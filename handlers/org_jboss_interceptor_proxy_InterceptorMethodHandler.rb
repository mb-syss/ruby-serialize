

class Org_jboss_interceptor_proxy_InterceptorMethodHandler < Java::Serialize::ObjectHandlers
  def writeObject(stream, obj, desc)
    stream.defaultWriteObject(obj, desc)
  end
end
