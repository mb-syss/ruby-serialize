

module Java
  module Config
    class RunConfig
      def initialize; end

      def checkRefs?
        true
      end

      def followRemoteRefs?
        true
      end

      def tryDeser?
        true
      end

      def tryMlet?
        true
      end

      def tryClassload?
        true
      end

      def useGadget?(g)
        g.auto?
      end

      def methodHash
        nil
      end

      def methodId
        -1
      end

      def methodBaseArgs
        [nil]
      end

      def methodArgIdx
        0
      end

      def methodSignature
        nil
      end
    end

    class PropRunConfig < RunConfig
      def initialize(props)
        @props = props
      end

      def checkRefs?
        @props.fetch('CHECK_REFS')
      end

      def followRemoteRefs?
        @props.fetch('FOLLOW_REMOTE_REFS')
      end

      def tryDeser?
        @props.fetch('TRY_DESER')
      end

      def tryMlet?
        @props.fetch('TRY_MLET')
      end

      def tryClassload?
        @props.fetch('TRY_CLASSLOAD')
      end

      def useGadget?(g)
        gs = @props['GADGETS']

        return g.auto? if gs.nil? || gs.empty?

        gs.split(',').map(&:strip).include?(g.id)
      end

      def methodHash
        @props['METHOD_HASH']
      end

      def methodId
        @props['METHOD_ID'] || -1
      end

      def methodSignature
        @props['METHOD_SIGNATURE']
      end
    end
  end
end
