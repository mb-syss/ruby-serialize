Java::Prober.register [

  Java::Prober::ExistsProbe.new('org.hibernate.property.BasicPropertyAccessor$BasicGetter',
                                t: ->(ctx) { ctx.gadget('hibernate') }),

  Java::Prober::ExistsProbe.new('org.hibernate.property.access.spi.GetterMethodImpl',
                                t: ->(ctx) { ctx.gadget('hibernate') }),

  Java::Prober::ExistsProbe.new('org.hibernate.validator.internal.util.annotationfactory.AnnotationProxy',
                                t: ->(ctx) { ctx.gadget('hibernate-validator') }),

  Java::Prober::ExistsProbe.new('org.hibernate.validator.internal.util.annotation.AnnotationProxy',
                                t: ->(ctx) { ctx.gadget('hibernate-validator') })

]
