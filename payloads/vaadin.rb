

require_relative '../serialize'
require_relative 'util'

module Java
  module Serialize
    module Payloads
      module Vaadin
        def make_get_property(obj, name)
          prop = Java::Serialize::JavaObject.new('Lcom/vaadin/data/util/NestedMethodProperty;', 'propertyName' => name,
                                                                                                'instance' => obj)

          propset = Java::Serialize::JavaObject.new('Lcom/vaadin/data/util/PropertysetItem;', 'map' => Java::Serialize::JavaObject.new('Ljava/util/HashMap;', 'elements' => { name => prop }),
                                                                                              'list' => Java::Serialize::JavaObject.new('Ljava/util/LinkedList;', 'elements' => [name]))

          Java::Serialize::Payloads::Util.make_tostring(propset)
        end
        module_function :make_get_property
        end
    end
  end
end
