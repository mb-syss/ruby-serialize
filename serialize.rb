#!/usr/bin/env ruby

require_relative 'data'
require 'json'

module Java
  module Serialize
    class ObjectHandlers
      def writeObject(_stream, _obj, _desc)
        raise NotImplementedError, to_s
      end

      def writeExternal(_stream, _obj, _desc)
        raise NotImplementedError, to_s
      end

      def readObject(_stream, _desc)
        raise NotImplementedError, to_s
      end
    end

    class Registry
      attr_accessor :loaded

      def initialize(base: '', clone: nil)
        @types = {}
        @handlers = {}
        @loaded = []
        @base = base

        # primitives
        %w[J I Z B C S F D].each do |t|
          @types[t] = { 'typeString' => t }
        end

        unless clone.nil?
          @base = clone.instance_variable_get :@base
          @loaded = (clone.instance_variable_get :@loaded).dup
          @handlers = (clone.instance_variable_get :@handlers).dup
          @types = (clone.instance_variable_get :@types).dup
        end
      end

      def load(filename)
        @loaded.push(filename)
        model = JSON.parse(File.read(@base + filename))
        model.each do |entry|
          ts = entry.fetch('typeString')
          @types[ts] = entry
        end
      end

      def dup
        Registry.new(clone: self)
      end

      def register(name, info)
        typeString = 'L' + name.tr('.', '/') + ';'
        info['typeString'] = 'L' + name.tr('.', '/') + ';'
        @types[typeString] = info
      end

      def getHandler(ts)
        raise KeyError if ts[0] != 'L' || ts[-1] != ';'

        handlerName = ts[1..-2].tr('/', '_').tr('$', '_')
        require_relative 'handlers/' + handlerName + '.rb'
        klass = Object.const_get(handlerName[0].upcase + handlerName[1..-1])
        klass.new
      end

      def writeObject(stream, obj, desc)
        ts = desc.fetch('typeString')
        getHandler(ts).writeObject(stream, obj, desc)
      end

      def writeExternal(stream, obj, desc)
        ts = desc.fetch('typeString')
        getHandler(ts).writeExternal(stream, obj, desc)
      end

      def getDescriptor(type)
        return @types[type] unless @types[type].nil?

        return nil if type == '' || type[0] != '['

        ctype = type[1..-1]
        compDesc = getDescriptor(ctype)

        raise KeyError, ctype if compDesc.nil?

        desc = {
          'name' => type,
          'typeString' => type
        }
        @types[type] = desc
        desc
      end

      def putDescriptor(type, desc)
        @types[type] = desc
      end
    end

    class JavaBase
      attr_accessor :type
      attr_accessor :desc
      end

    class JavaObject < JavaBase
      attr_accessor :fields

      def initialize(type, fields)
        @type = type
        @fields = fields
      end
    end

    class JavaCustomObject < JavaObject
      def initialize(type, fields, desc)
        super(type, fields)
        @desc = desc
      end
    end

    class JavaProxy < JavaObject
      def initialize(intf, handler)
        super('', { 'h' => handler })
        @desc = {
          'proxy' => true,
          'serialVersion' => 0,
          'hasWriteObject' => false,
          'superType' => 'Ljava/lang/reflect/Proxy;',
          'interfaces' => intf
        }
    end
    end

    class JavaClass < JavaBase
      def initialize(type)
        @type = type
      end
    end

    class ObjectStreamClass < JavaBase
      def initialize(type)
        @type = type
      end
    end

    class JavaArray < JavaBase
      attr_accessor :componentType
      attr_accessor :values

      def initialize(componentType, values)
        @type = '[' + componentType
        @componentType = componentType
        @values = values
      end

      def primitive
        code = @componentType[0]
        code != 'L' && code != '['
      end
      end

    class JavaEnum < JavaBase
      attr_accessor :name

      def initialize(type, name)
        @name = name
        @type = type
      end
    end

    class ObjectOutputStream
      TC_BASE = 0x70
      TC_NULL = 0x70
      TC_REFERENCE = 0x71
      TC_CLASSDESC = 0x72
      TC_OBJECT = 0x73
      TC_STRING = 0x74
      TC_ARRAY = 0x75
      TC_CLASS = 0x76
      TC_BLOCKDATA = 0x77
      TC_ENDBLOCKDATA = 0x78
      TC_RESET = 0x79
      TC_BLOCKDATALONG = 0x7A
      TC_EXCEPTION = 0x7B
      TC_LONGSTRING = 0x7C
      TC_PROXYCLASSDESC = 0x7D
      TC_ENUM = 0x7E
      TC_MAX = 0x7E

      def initialize(out, registry)
        @out = out
        @registry = registry
        @enableOverride = false
        @enableAnnotateClass = false
        @enableAnnotateProxyClass = false
        @blockMode = false
        @blockBuf = StringIO.new('', 'wb+')
        @blockPos = 0
        @protocol = 2
        @baseWireHandle = 0x7e0000
        @depth = 0
        @handles = {}.compare_by_identity
        writeStreamHeader
      end

      def writeStreamHeader
        enc = [0xAC, 0xED, 0x00, 0x05].pack('C*')
        @out.write(enc)
      end

      def setBlockMode(mode)
        obm = @blockMode
        return obm if mode == obm
        flush
        @blockMode = mode
        obm
      end

      def flush
        return if @blockPos == 0

        writeBlockHeader(@blockPos) if @blockMode

        @out.write(@blockBuf.string)
        @blockBuf = StringIO.new('', 'wb+')
        @blockPos = 0
      end

      def writeBlockHeader(len)
        if len <= 0xFF
          @out.write([TC_BLOCKDATA, len].pack('CC'))
        else
          @out.write([TC_BLOCKDATALONG, len].pack('Ci>'))
        end
      end

      def endBlockMode
        setBlockMode(false)
        @out.write([TC_ENDBLOCKDATA].pack('C'))
      end

      def writeByte(b)
        enc = [b].pack('C')
        if @blockMode
          @blockBuf.write(enc)
          @blockPos += 1
        else
          @out.write(enc)
        end
      end

      def writeBytes(data)
        if @blockMode
          @blockBuf.write(data)
          @blockPos += data.length
        else
          @out.write(data)
        end
      end

      def assign(obj)
        return if obj.nil?

        i = @handles.length
        @handles[obj] = i
        raise 'Missed' if i == @handles.length
      end

      def lookup(obj)
        r = @handles[obj]
        r.nil? ? -1 : r
      end

      def writeNull
        writeByte(TC_NULL)
      end

      def writeHandle(hdl)
        writeByte(TC_REFERENCE)
        writeBytes([hdl + @baseWireHandle].pack('l>'))
      end

      def writeString(s, unshared)
        assign(unshared ? nil : s)
        enc = s.encode('utf-8')
        if enc.length < 0xFFFF
          writeByte(TC_STRING)
          writeBytes([s.length].pack('s>'))
          writeBytes(enc)
        else
          raise NotImplementedError
        end
      end

      def writeUTF(s)
        writeBytes([s.length].pack('s>'))
        writeBytes(s.encode(Encoding::UTF_8))
      end

      def writeTypeString(type)
        handle = -1
        if type.nil?
          writeNull
        elsif (handle = lookup(type)) != -1
          writeHandle(handle)
        else
          writeString(type, false)
        end
      end

      def writeEnum(en, desc, unshared)
        writeByte(TC_ENUM)

        stype = desc.fetch('superType', 'Ljava/lang/Object;')
        sdesc = @registry.getDescriptor(stype)

        raise KeyError if sdesc.nil?

        writeClassDesc(stype == 'Ljava/lang/Enum;' ? desc : sdesc, false)

        assign(unshared ? null : en)
        writeString(en.name, false)
      end

      def writeClassDesc(desc, unshared)
        handle = -1
        if desc.nil?
          writeNull
        elsif !unshared && (handle = lookup(desc)) != -1
          writeHandle(handle)
        elsif desc.fetch('proxy', false)
          writeProxyDesc(desc, unshared)
        else
          writeNonProxyDesc(desc, unshared)
        end
      end

      def writeClass(clazz, unshared)
        writeByte(TC_CLASS)
        desc = @registry.getDescriptor(clazz)
        if desc.nil?
          # dummy
          desc = { 'typeString' => clazz }
        end
        writeClassDesc(desc, false)
        assign(unshared ? null : clazz)
      end

      def writeProxyDesc(desc, unshared)
        writeByte(TC_PROXYCLASSDESC)
        assign(unshared ? null : desc)

        interfaces = desc.fetch('interfaces', [])
        # 0 interfaces
        writeBytes([interfaces.length].pack('i>'))

        for interface in interfaces
          writeUTF(interface)
        end

        setBlockMode(true)
        annotateProxyClass(desc.class) if @annotateProxyClass
        endBlockMode
        sdesc = @registry.getDescriptor(desc.fetch('superType', 'Ljava/lang/Object;'))

        raise KeyError if sdesc.nil?
        writeClassDesc(sdesc, false)
      end

      def writeNonProxyDesc(desc, unshared)
        writeByte(TC_CLASSDESC)
        assign(unshared ? null : desc)

        ts = desc.fetch('typeString')
        arrsep = ts.rindex('[')
        if ts[0] == 'L'
          ts = ts[1..-2].tr('/', '.')
        elsif !arrsep.nil? && ts[arrsep + 1] == 'L'
          ts = ts[0..arrsep] + ts[arrsep + 1..-1].tr('/', '.')
        end
        writeUTF(ts)
        writeBytes([desc.fetch('serialVersion', 0)].pack('q>'))

        flags = 0
        if desc.fetch('externalizable', false)
          flags |= 0x4 # SC_EXTERNALIZABLE
          if @protocol != 1
            flags |= 0x08 # SC_BLOCK_DATA
          end
        else
          flags |= 0x2 # SC_SERIALIZABLE
        end

        if desc.fetch('hasWriteObject', false)
          flags |= 0x1 # SC_WRITE_METHOD
        end

        if desc.fetch('enum', false)
          flags |= 0x10 # SC_ENUM
        end

        fields = desc.fetch('fields', [])

        writeByte(flags)
        writeBytes([fields.length].pack('s>'))

        fields.each do |f|
          fn = f.fetch('name')
          ts = f.fetch('typeString')
          typeCode = ts[0]
          writeByte(typeCode.ord)
          writeUTF(fn)

          writeTypeString(ts) if typeCode == 'L' || typeCode == '['
        end

        # empty annotation block
        setBlockMode(true)
        annotateClass(desc.class) if @annotateClass
        endBlockMode

        stype = desc.fetch('superType', nil)
        sdesc = @registry.getDescriptor(stype) unless stype.nil?
        writeClassDesc(sdesc, false)
      end

      def writeArray(array, desc, unshared)
        writeByte(TC_ARRAY)
        writeClassDesc(desc, false)
        assign(unshared ? nil : array)

        writeBytes([array.values.length].pack('l>'))

        array.values.each do |elem|
          if array.primitive
            writePrimitive(array.componentType, elem)
          else
            writeObject0(elem, false)
          end
        end
      end

      def writePrimitive(type, val)
        val = 0 if val.nil?

        case type
        when 'Z' # boolean
          writeByte(val ? 1 : 0)
          return
        when 'B' # byte
          writeByte(val)
          return
        when 'C' # char
          packed = [val].pack('S>')
        when 'S' # short
          packed = [val].pack('s>')
        when 'I' # int
          packed = [val].pack('l>')
        when 'J' # long
          packed = [val].pack('q>')
        when 'D' # double
          packed = [val].pack('G')
        when 'F' # float
          packed = [val].pack('g')
        else
          raise NotImplementedError, type
        end
        writeBytes(packed)
      end

      def writeObjectOverride(o); end

      def writeObject(o)
        return writeObjectOverride(o) if @enableOverride
        writeObject0(o, false)
      end

      def writeObject0(obj, unshared)
        obm = setBlockMode(false)
        @depth += 1
        begin
          return writeNull if obj.nil?

          if !unshared && (h = lookup(obj)) != -1
            return writeHandle(h)
          elsif obj.instance_of? JavaClass
            if !unshared && (h = lookup(obj.type)) != -1
              return writeHandle(h)
            else
              return writeClass(obj.type, unshared)
            end
          elsif obj.instance_of? ObjectStreamClass
            if !unshared && (h = lookup(obj.type)) != -1
              return writeHandle(h)
            else
              return writeClassDesc(@registry.getDescriptor(obj.type), unshared)
            end
          end

          # writeReplace

          return writeString(obj, unshared) if obj.instance_of? String

          desc = if obj.respond_to?('desc') && !obj.desc.nil?
                   obj.desc
                 else
                   @registry.getDescriptor(obj.type)
                 end
          if desc.nil?
            raise KeyError, obj.type
          elsif obj.type[0] == '['
            writeArray(obj, desc, unshared)
          elsif desc.fetch('enum', false)
            writeEnum(obj, desc, unshared)
          else
            writeOrdinaryObject(obj, desc, unshared)
          end
        ensure
          @depth -= 1
          setBlockMode(obm)
        end
      end

      def writeOrdinaryObject(obj, desc, unshared)
        writeByte(TC_OBJECT)
        writeClassDesc(desc, false)
        assign(unshared ? nil : obj)

        if !desc.fetch('proxy', false) && desc.fetch('externalizable', false)
          writeExternalData(obj, desc)
        else
          writeSerialData(obj, desc)
        end
      end

      def writeSerialData(obj, desc)
        slots = [desc]
        cur = desc
        until cur.fetch('superType', nil).nil?
          cur = @registry.getDescriptor(cur.fetch('superType'))

          break if cur.nil?

          slots += [cur]
        end

        slots.reverse.each do |slotDesc|
          if slotDesc.fetch('hasWriteObject', false)
            setBlockMode(true)
            @registry.writeObject(self, obj, slotDesc)
            endBlockMode
          else
            defaultWriteFields(obj, slotDesc)
          end
        end
      end

      def writeExternalData(obj, desc)
        if @protocol == 1
          @registry.writeExternal(self, obj, desc)
        else
          setBlockMode(true)
          @registry.writeExternal(self, obj, desc)
          endBlockMode
        end
      end

      def defaultWriteObject(obj, desc)
        setBlockMode(false)
        defaultWriteFields(obj, desc)
        setBlockMode(true)
      end

      def defaultWriteFields(obj, desc)
        primFields = []
        objFields = []

        desc.fetch('fields', []).each do |f|
          ts = f.fetch('typeString')
          if ts[0] == '[' || ts[0] == 'L'
            objFields += [f]
          else
            primFields += [f]
          end
        end

        values = obj.fields
        primFields.each do |f|
          fn = f.fetch('name')
          ft = f.fetch('typeString')
          val = values.fetch(fn, nil)
          writePrimitive(ft, val)
        end

        objFields.each do |f|
          fn = f.fetch('name')
          val = values.fetch(fn, nil)
          writeObject0(val, f.fetch('unshared', false))
        end
      end
    end
  end
end
