Java::Prober.register [

  Java::Prober::ExistsProbe.new('bsh.XThis',
                                t: ->(ctx) { ctx.gadget('beanshell') }),

  Java::Prober::ExistsProbe.new('com.mchange.v2.c3p0.PoolBackedDataSource',
                                t: lambda do |ctx|
                                  areg = ctx.reg.dup
                                  areg.load('model/c3p0.json')

                                  ctx.pushf(Java::Prober::DeserProbe.new(
                                              'com.mchange.v2.c3p0.PoolBackedDataSource',
                                              reg: areg,
                                              fields: { 'identityToken' => 'foobar' },
                                              t: ->(ctx) { ctx.gadget('c3p0') },
                                              f: lambda do |ctx|
                                                # check legacy
                                                breg = ctx.reg.dup
                                                breg.load('model/c3p0-legacy.json')
                                                ctx.pushf(Java::Prober::DeserProbe.new(
                                                            'com.mchange.v2.c3p0.PoolBackedDataSource',
                                                            reg: breg,
                                                            fields: { 'identityToken' => 'foobar' },
                                                            t: lambda do |ctx|
                                                              ctx.gadget('c3p0')
                                                              ctx.flag('c3p0-legacy')
                                                            end,
                                                            f: ->(_ctx) { error 'Incompatible C3P0' }
                                                ))
                                              end
                                  ))
                                end),

  Java::Prober::ExistsProbe.new('org.apache.commons.fileupload.disk.DiskFileItem',
                                t: lambda { |ctx|
                                     ctx.pushf(Java::Prober::DeserProbe.new(
                                                 'org.apache.commons.fileupload.disk.DiskFileItem',
                                                 desc: { 'serialVersion' => -8_653_385_846_894_047_688 },
                                                 t: ->(ctx) { ctx.gadget('fileupload') },
                                                 f: ->(_ctx) { error 'Incompatible commons-fileupload' }
                                     ))
                                   }),

  Java::Prober::ExistsProbe.new('org.apache.wicket.util.upload.DiskFileItem',
                                t: ->(ctx) { ctx.gadget('wicket-fileupload') }),

  Java::Prober::ExistsProbe.new('org.codehaus.groovy.runtime.MethodClosure',
                                t: lambda do |ctx|
                                  ctx.pushf(Java::Prober::DeserProbe.new(
                                              'org.codehaus.groovy.runtime.MethodClosure',
                                              desc: { 'serialVersion' => 1_228_988_487_386_910_280 },
                                              t: ->(ctx) { ctx.gadget('groovy') }
                                  ))
                                end),

  Java::Prober::ExistsProbe.new('net.sf.json.JSONObject',
                                t: ->(ctx) { ctx.gadget('json') }),

  Java::Prober::ExistsProbe.new('org.python.core.PyFunction',
                                t: ->(ctx) { ctx.gadget('jython') }),

  Java::Prober::ExistsProbe.new('org.apache.myfaces.view.facelets.el.ValueExpressionMethodExpression',
                                t: lambda { |ctx|
                                  ctx.push(ExistsProbe.new('org.apache.el.ExpressionFactoryImpl'))
                                  ctx.push(ExistsProbe.new('de.odysseus.el.ExpressionFactoryImpl'))
                                  ctx.push(ExistsProbe.new('com.sun.el.ExpressionFactoryImpl'))
                                  ctx.gadget('myfaces')
                                }),

  Java::Prober::ExistsProbe.new('com.sun.syndication.feed.impl.ObjectBean',
                                t: ->(ctx) { ctx.gadget('rome') }),
  Java::Prober::ExistsProbe.new('com.rometools.rome.feed.impl.ObjectBean',
                                t: ->(ctx) { ctx.gadget('rome') }),

  Java::Prober::ExistsProbe.new('org.jboss.interceptor.proxy.InterceptorMethodHandler',
                                t: ->(ctx) { ctx.gadget('jboss') }),
  Java::Prober::ExistsProbe.new('org.jboss.weld.interceptor.proxy.InterceptorMethodHandler',
                                t: ->(ctx) { ctx.gadget('jboss') }),

  Java::Prober::ExistsProbe.new('org.mozilla.javascript.NativeJavaObject',
                                t: ->(ctx) { ctx.gadget('rhino') }),

  Java::Prober::ExistsProbe.new('clojure.main$eval_opt',
                                t: ->(ctx) { ctx.gadget('clojure') }),

  Java::Prober::ExistsProbe.new('com.vaadin.data.util.NestedMethodProperty',
                                t: ->(ctx) { ctx.gadget('vaadin') })

]
