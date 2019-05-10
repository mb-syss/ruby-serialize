
class Java_util_HashMap < Java::Serialize::ObjectHandlers
  def writeObject(stream, obj, desc)
    elems = obj.fields.fetch('elements', [])
    obj.fields['loadFactor'] = obj.fields.fetch('loadFactor', 0.5)

    stream.defaultWriteObject(obj, desc)

    # map.buckets
    stream.writeBytes([elems.length].pack('i>'))
    # size
    stream.writeBytes([elems.length].pack('i>'))

    elems.each do |key, value|
      stream.writeObject(key)
      stream.writeObject(value)
    end
  end
end
