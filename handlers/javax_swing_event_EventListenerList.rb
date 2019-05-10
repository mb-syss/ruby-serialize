class Javax_swing_event_EventListenerList < Java::Serialize::ObjectHandlers
  def writeObject(stream, obj, desc)
    stream.defaultWriteObject(obj, desc)
    listeners = obj.fields.fetch('listeners', [])
    for le in listeners
      stream.writeObject(le[0])
      stream.writeObject(le[1])
    end

    stream.writeObject(nil)
  end
end
