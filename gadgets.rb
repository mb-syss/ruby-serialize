require_relative 'prober'
require_relative 'config'

module Java
  module Gadgets
    def register(gadget)
      BuiltinGadgets.register(gadget)
    end
    module_function :register

    class BuiltinGadgets
      @@gadgets = []

      def initialize
        Dir[File.dirname(__FILE__) + '/gadgets/*.rb'].sort.each do |file|
          require file
        end
      end

      def self.register(g)
        @@gadgets.push(g) unless @@gadgets.include?(g)
      end

      def get(id)
        @@gadgets.each do |gadget|
          return gadget if gadget.id == id
        end
        nil
      end

      def find(ctx, params: {}, rc: Java::Config::RunConfig.new)
        matches = []

        @@gadgets.each do |gadget|
          unless rc.useGadget?(gadget)
            info 'Skipping gadget ' + gadget.id + ' based on config'
            next
          end
          if gadget.usable(ctx, params: params)
            matches.push(gadget)
          else
            debug 'No match ' + gadget.to_s
          end
        end

        matches
      end
    end

    class Gadget
      def id
        raise
      end

      def usable(_ctx, params: {})
        false
      end

      def targets
        # exec, bytecode, classload, jndi, custom
        []
      end

      def priority
        0
      end

      def auto?
        true
      end

      def create; end
    end
  end
end
