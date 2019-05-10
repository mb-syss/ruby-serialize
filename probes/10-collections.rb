Java::Prober.register [

  Java::Prober::ExistsProbe.new('org.apache.commons.collections.functors.InvokerTransformer',
                                t: lambda { |ctx|
                                     ctx.pushf(Java::Prober::DeserProbe.new(
                                                 'org.apache.commons.collections.functors.InvokerTransformer',
                                                 desc: { 'serialVersion' => -8_653_385_846_894_047_688 },
                                                 t: ->(ctx) { ctx.gadget('collections') }
                                     ))
                                   }),

  Java::Prober::ExistsProbe.new('org.apache.commons.collections4.functors.InvokerTransformer',
                                t: lambda { |ctx|
                                     ctx.pushf(Java::Prober::DeserProbe.new(
                                                 'org.apache.commons.collections4.functors.InvokerTransformer',
                                                 desc: { 'serialVersion' => -8_653_385_846_894_047_688 },
                                                 t: ->(ctx) { ctx.gadget('collections') }
                                     ))
                                   })

]
