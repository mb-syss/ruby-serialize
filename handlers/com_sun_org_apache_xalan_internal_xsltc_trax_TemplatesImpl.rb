

class Com_sun_org_apache_xalan_internal_xsltc_trax_TemplatesImpl < Java::Serialize::ObjectHandlers
  def writeObject(stream, obj, desc)
    stream.defaultWriteObject(obj, desc)
    stream.writeByte(0)
  end
end
