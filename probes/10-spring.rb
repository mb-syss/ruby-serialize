Java::Prober.register [

  Java::Prober::ExistsProbe.new('org.springframework.core.SerializableTypeWrapper$MethodInvokeTypeProvider',
                                t: ->(ctx) { ctx.gadget('spring-typeprov') }),

  Java::Prober::ExistsProbe.new('org.springframework.transaction.jta.JtaTransactionManager',
                                t: ->(ctx) { ctx.gadget('spring-jta') })

]
