
class Javax_management_ObjectName < Java::Serialize::ObjectHandlers
  def writeObject(stream, obj, desc)
    name = obj.fields.fetch('name', '')
    stream.defaultWriteObject(obj, desc)
    stream.writeObject(name)
    end

  def readObject(stream, _desc)
    { 'name' => stream.read_object }
  end
end
