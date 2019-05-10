
class Com_atomikos_icatch_jta_RemoteClientUserTransaction < Java::Serialize::ObjectHandlers
  def writeExternal(stream, obj, _desc)
    stream.writeObject(nil)
    stream.writeObject(obj.fields.fetch('name_', nil))
    stream.writeObject(obj.fields.fetch('initialContextFactory_', nil))
    stream.writeObject(obj.fields.fetch('providerUrl_', nil))
    stream.writeBytes([0].pack('i>')) # timeout_
  end
end
