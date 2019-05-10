Java::Prober.register [

  Java::Prober::ExistsProbe.new('java.util.HashSet', f: ->(_ctx) { raise },
                                                     t: lambda { |ctx|
      ctx.pushf(Java::Prober::DeserProbe.new('java.util.HashSet', desc: {
                                               'serialVersion' => -5_024_744_406_713_321_676,
                                               'hasWriteObject' => true,
                                               'fields' => [],
                                               'superType' => 'Ljava/util/AbstractSet;'
                                             }, t: ->(ctx) { ctx.gadget('hashdos') }))}),

  Java::Prober::ExistsProbe.new('doesnotexist', t: ->(_ctx) { raise 'Should not exist' }),

  Java::Prober::ExistsProbe.new('java.lang.String', f: ->(_ctx) { raise })

]
