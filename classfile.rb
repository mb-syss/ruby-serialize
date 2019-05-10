require 'zip'

module Java
  module Serialize
    module Classfile
      def patch_translet_unique
        rand = (0...8).map { (65 + rand(26)).chr }.join
        d = File.binread('meterpreter/metasploit/TransletPayload.class')
        patch_class(d, 'Translet' + rand, {})
      end
      module_function :patch_translet_unique

      def get_string(s)
        # not quite correct
        s['data']
      end
      module_function :get_string

      def get_class_name(pool, idx)
        namei = pool[idx - 1]['data'].unpack('S>')[0]
        get_string(pool[namei - 1])
      end
      module_function :get_class_name

      def patch_class(d, pname, pfields)
        pos = 0
        magic, minor, major, cpoolcount = d[0..10].unpack('I>S>S>S>')
        pos += 10

        cpool = []
        i = 0
        while i < cpoolcount - 1

          tag = d[pos..pos + 1].unpack('C')[0]
          pos += 1
          datalen = 0
          case tag
          when 1
            strlen = d[pos..pos + 2].unpack('S>')[0]
            pos += 2
            datalen = strlen
          when 7, 8, 16
            datalen = 2
          when 15
            datalen = 3
          when 3, 4, 9, 10, 11, 12, 18
            datalen = 4
          when 5, 6
            datalen = 8
            i += 1 # + extra slot
          else
            raise KeyError, tag
          end

          data = d[pos..pos + datalen - 1]
          pos += datalen

          cpool << {
            'idx' => i,
            'tag' => tag,
            'len' => datalen,
            'data' => data
          }
          i += 1
        end

        flags, thiscl, supercl, intcnt = d[pos..pos + 8].unpack('S>S>S>S>')
        pos += 8

        cname = get_class_name(cpool, thiscl)

        datapos = pos
        pos += 2 * intcnt
        fcnts = d[pos..pos + 2].unpack('S>')[0]
        pos += 2

        fields = {}
        for f in 0..fcnts - 1
          accflags, nameidx, descidx, attrcnt = d[pos..pos + 8].unpack('S>S>S>S>')
          pos += 8

          fname = get_string(cpool[nameidx - 1])
          arefidx = 0
          avalidx = 0
          coff = 0
          val = nil

          for a in 0..attrcnt - 1
            attrnameidx, attrlen = d[pos..pos + 6].unpack('S>I>')
            pos += (6 + attrlen)
            type = get_string(cpool[attrnameidx - 1])
            next unless type == 'ConstantValue' && accflags & 0x18 == 0x18
            coff = pos - 2
            arefidx = d[pos - 2..pos].unpack('S>')[0]
            avalidx = cpool[arefidx - 1]['data'].unpack('S>')[0]
            val = get_string(cpool[avalidx - 1])
          end

          fields[fname] = {
            'name' => fname,
            'refidx' => arefidx,
            'validx' => avalidx,
            'val' => val,
            'coff' => coff
          }
        end

        unless pname.nil?
          # add name to constant pool
          cpool << {
            'tag' => 1,
            'data' => pname
          }
          cpoolcount += 1
          newidx = cpool.length
          ce = cpool[thiscl - 1]
          ce['data'] = [newidx].pack('S>')
        end

        pfields.each do |key, entry|
          f = fields[key]
          if f.nil? || f['refidx'] == 0
            STDERR.puts 'Field not found ' + key
            next
          end
          # add string value to constant pool
          cpool << {
            'tag' => 1,
            'data' => entry
          }
          cpoolcount += 1
          # add new reference

          cpool << {
            'tag' => 8,
            'data' => [cpool.length].pack('S>')
          }
          cpoolcount += 1

          # patch constant reference
          refidx = cpool.length
          coff = f['coff']
          d[coff..coff + 1] = [refidx].pack('S>')
        end

        out = ''.b
        out += d[0..7]
        out += [cpoolcount].pack('S>')

        cpool.each do |cpe|
          if cpe['tag'] == 1
            out += [cpe['tag']].pack('C')
            out += [cpe['data'].length].pack('S>')
            out += cpe['data']
          else
            out += [cpe['tag']].pack('C')
            out += cpe['data']
          end
        end

        out += [flags, thiscl, supercl, intcnt].pack('S>S>S>S>')
        # remainder
        out += d[datapos..-1]
        out
      end
      module_function :patch_class

      T_UTF8 = 1
      T_CLASS = 7
      T_STRINGREF = 8
      T_FIELDREF = 9
      T_METHODREF = 10
      T_NAMEANDTYPE = 12

      def gen_config_class(name, props)
        cpool = []
        minor = 0
        major = 49 # Java5+
        flags = 0x1 | 0x10 | 0x1000 # ACC_PUBLIC | ACC_FINAL | ACC_SYNTHETIC

        # this_class
        cpool << { 'tag' => T_UTF8, 'data' => name }
        cpool << { 'tag' => T_CLASS, 'data' => [cpool.length].pack('S>') }
        thiscl = cpool.length
        cpool << { 'tag' => T_UTF8, 'data' => 'java/lang/Object' }
        cpool << { 'tag' => T_CLASS, 'data' => [cpool.length].pack('S>') }
        supercl = cpool.length
        cpool << { 'tag' => T_UTF8, 'data' => '<clinit>' }
        clinitidx = cpool.length
        cpool << { 'tag' => T_UTF8, 'data' => '<init>' }
        initidx = cpool.length
        cpool << { 'tag' => T_UTF8, 'data' => '()V' }
        descidx = cpool.length
        cpool << { 'tag' => T_UTF8, 'data' => 'Code' }
        codeidx = cpool.length
        cpool << { 'tag' => T_UTF8, 'data' => 'CONFIG' }
        configidx = cpool.length
        cpool << { 'tag' => T_UTF8, 'data' => 'Ljava/util/Map;' }
        configdescidx = cpool.length
        cpool << { 'tag' => T_NAMEANDTYPE, 'data' => [configidx, configdescidx].pack('S>S>') }
        configntidx = cpool.length
        cpool << { 'tag' => T_FIELDREF, 'data' => [thiscl, configntidx].pack('S>S>') }
        configrefidx = cpool.length
        cpool << { 'tag' => T_UTF8, 'data' => 'java/util/HashMap' }
        cpool << { 'tag' => T_CLASS, 'data' => [cpool.length].pack('S>') }
        mapclidx = cpool.length
        cpool << { 'tag' => T_NAMEANDTYPE, 'data' => [initidx, descidx].pack('S>S>') }
        cpool << { 'tag' => T_METHODREF, 'data' => [mapclidx, cpool.length].pack('S>S>') }
        mapinitidx = cpool.length
        cpool << { 'tag' => T_UTF8, 'data' => 'put' }
        cpool << { 'tag' => T_UTF8, 'data' => '(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;' }
        cpool << { 'tag' => T_NAMEANDTYPE, 'data' => [cpool.length - 1, cpool.length].pack('S>S>') }
        cpool << { 'tag' => T_METHODREF, 'data' => [mapclidx, cpool.length].pack('S>S>') }
        mapputidx = cpool.length

        constmap = []
        props.each do |key, entry|
          cpool << { 'tag' => T_UTF8, 'data' => key.to_s }
          cpool << { 'tag' => T_STRINGREF,	'data' => [cpool.length].pack('S>') }
          cpool << { 'tag' => T_UTF8, 'data' => entry.to_s }
          cpool << { 'tag' => T_STRINGREF,	'data' => [cpool.length].pack('S>') }
          constmap += [cpool.length]
        end

        out = ''.b
        out += [0xCAFEBABE, minor, major, cpool.length + 1].pack('I>S>S>S>')

        cpool.each do |cpe|
          if cpe['tag'] == 1
            out += [cpe['tag']].pack('C')
            out += [cpe['data'].length].pack('S>')
            out += cpe['data']
          else
            out += [cpe['tag']].pack('C')
            out += cpe['data']
          end
        end

        out += [flags, thiscl, supercl, 0].pack('S>S>S>S>')
        # 0 intf

        out += [1].pack('S>')
        # 1 fields - CONFIG

        field_info = ''.b
        field_info += [0x1 | 0x8 | 0x10, configidx, configdescidx, 0].pack('S>S>S>S>')
        out += field_info

        out += [1].pack('S>')
        # 1 methods - only static initializer

        method_info = ''.b
        method_info += [0x0, clinitidx, descidx, 1].pack('S>S>S>S>')

        max_stack = 100
        max_locals = 10

        bytecode = ''.b
        bytecode += "\xbb".b # new
        bytecode += [mapclidx].pack('S>')

        bytecode += "\x4b".b # astore_0
        bytecode += "\x2a".b # aload_0

        bytecode += "\xb7".b # invokespecial
        bytecode += [mapinitidx].pack('S>')

        bytecode += "\x2a".b # aload_0
        bytecode += "\xb3".b # putstatic
        bytecode += [configrefidx].pack('S>')

        constmap.each do |idx|
          bytecode += "\x2a".b # aload_0

          bytecode += "\x13".b
          bytecode += [idx - 2].pack('S>')

          bytecode += "\x13".b
          bytecode += [idx].pack('S>')

          bytecode += "\xb6".b
          bytecode += [mapputidx].pack('S>')
        end

        bytecode += "\xb1".b # return

        # code attribute
        code_attr = ''.b
        code_attr += [max_stack, max_locals, bytecode.length].pack('S>S>I>')
        code_attr += bytecode
        # no exception table, no attrs
        code_attr += [0, 0].pack('S>S>')

        method_info += [codeidx, code_attr.length].pack('S>I>')
        method_info += code_attr

        out += method_info

        out += [0].pack('S>')
        # 0 attrs

        out
      end
      module_function :gen_config_class
      end
  end
end
