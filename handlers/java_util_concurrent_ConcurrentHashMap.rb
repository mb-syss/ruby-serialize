
class Java_util_concurrent_ConcurrentHashMap < Java::Serialize::ObjectHandlers
  def writeObject(stream, obj, desc)
    elems = obj.fields.fetch('elements', [])
    stream.defaultWriteObject(obj, desc)

    elems.each do |key, value|
      stream.writeObject(key)
      stream.writeObject(value)
    end

    stream.writeObject(nil)
    stream.writeObject(nil)
    end
end
