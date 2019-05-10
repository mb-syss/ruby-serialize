Java::Prober.register [

  Java::Prober::ExistsProbe.new('com.sun.org.apache.xalan.internal.xsltc.trax.TemplatesImpl',
                                t: lambda do |ctx|
                                  ctx.reg.load('model/jdk-templates.json')
                                  ctx.pushf(Java::Prober::DeserProbe.new(
                                              'com.sun.org.apache.xalan.internal.xsltc.trax.TemplatesImpl',
                                              reg: ctx.reg,
                                              f: lambda do |ctx|
                                                ctx.flag('secmgr')
                                                ctx.flag('nojdktemplates')
                                              end
                                  ))
                                end),

  Java::Prober::ExistsProbe.new('org.apache.xalan.xsltc.trax.TemplatesImpl'),

  Java::Prober::ExistsProbe.new('com.sun.rowset.JdbcRowSetImpl'),

  Java::Prober::ExistsProbe.new('sun.reflect.annotation.AnnotationInvocationHandler',
                                t: lambda do |ctx|
                                  ctx.pushf(Java::Prober::DeserProbe.new(
                                              'sun.reflect.annotation.AnnotationInvocationHandler',
                                              reg: ctx.reg,
                                              fields: {
                                                'type' => Java::Serialize::JavaClass.new('java.lang.annotation.Retention'),
                                                'memberValues' => Java::Serialize::JavaObject.new('Ljava/util/HashMap;', {})
                                              },
                                              t: lambda do |ctx|
                                                ctx.pushf(Java::Prober::DeserProbe.new(
                                                            'sun.reflect.annotation.AnnotationInvocationHandler',
                                                            reg: ctx.reg,
                                                            fields: {
                                                              'type' => Java::Serialize::JavaClass.new('java.lang.Object'),
                                                              'memberValues' => Java::Serialize::JavaObject.new('Ljava/util/HashMap;', {})
                                                            },
                                                            t: ->(ctx) { ctx.flag('anninvh-universal') }
                                                ))
                                              end
                                  ))
                                end),

  Java::Prober::ExistsProbe.new('org.springframework.aop.framework.JdkDynamicAopProxy')

]
