require_relative 'serialize'
require_relative 'jrmp'
require_relative 'jmx'
require_relative 'rmi'
require_relative 'config'

module Java
  module Runner
    class RMICheck
      attr_reader :jmxprober

      def initialize(host, port, ssl: false, username: nil, password: nil, rc: Java::Config::RunConfig.new)
        @host = host
        @port = port
        @ssl = ssl
        @jmxcreds = nil
        if !username.nil? && !password.nil?
          @jmxcreds = Java::Serialize::JavaArray.new('Ljava/lang/String;', %w[test test])
        end

        @rc = rc

        @reg = Java::Serialize::Registry.new(base: File.dirname(__FILE__) + '/')
        @reg.load('model/base-java9.json')
        @reg.load('model/rmi.json')
      end

      def run
        prober = Java::RMI::RMIProber.new(@host, @port, @reg, ssl: @ssl, rc: @rc)
        vectors = prober.run

        if @rc.checkRefs?
          foundobjects = prober.objects
          unless foundobjects.empty?
            info 'Found ' + foundobjects.length.to_s + ' referenced objects, following references'

            foundobjects.each do |name, obj|
              unless @rc.followRemoteRefs?
                if obj['host'] != @host && !obj['host'].start_with?('127.')
                  info 'Skipping possibly remote object ' + name + ' pointing to ' + obj['host']
                  return
                end
              end

              if name == 'jmxrmi'
                prober = Java::JMX::JMXProber.new(name, obj, @reg, @host, jmxcreds: @jmxcreds, rc: @rc)
                @jmxprober = prober
              else
                info 'Custom object found ' + name

                prober = Java::JRMP::ReferenceProber.new(name, obj, @reg, @host, rc: @rc)
              end

              begin
                v = prober.run
                vectors += v unless v.nil?
              rescue Java::JRMP::JRMPError => e
                root = Java::JRMP.unwrap_exception(e.ex)
                error 'Probe failed ' + root.to_s
              rescue Exception => e
                error 'Probe failed ' + e.to_s
                debug e.backtrace.to_s
                prober.close
                raise
              end
              prober.close
            end
          end
          end

        dedupvecs = []
        dedup = Set[]
        gadgets = Set[]
        vectors.sort { |a, b| a.prio - b.prio }.each do |vector|
          i = vector.id
          if !dedup.include?(i)
            dedup.add(i)
          else
            next
          end
          gadgets += vector.context.gadgets if vector.respond_to?('context')
          dedupvecs.push(vector)
        end
        info format('Identified %d attack vector(s), gadgets %s', dedupvecs.length, gadgets.to_a.to_s)
        dedupvecs
      end
    end
    end
end
