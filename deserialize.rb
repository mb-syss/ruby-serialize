#!/usr/bin/env ruby

module Java
  module Deserialize
    class DeserializeException < RuntimeError
      def inititialize(ex)
        @ex = ex
      end
    end

    class ObjectInputStream
      def initialize(input, reg)
        @input = input
        @handles = []
        @registry = reg
      end

      def read_utf
        len = @input.read(2).unpack('S>')[0]
        @input.read(len)
      end

      def read_handle
        handle = @input.read(4).unpack('I>')[0] - 0x7e0000
        @handles[handle]
      end

      def read_string
        read_string_type(@input.read(1).unpack('C')[0])
      end

      def read_string_type(type)
        if type == 0x70
          return
        elsif type == 0x71
          return read_handle
        elsif type != 0x74 # TC_BLOCKDATA
          raise 'Unexpected type: Not string ' + type.to_s
        end

        str = read_utf
        @handles.push(str)
        str
      end

      def read_blockdata
        type = @input.read(1).unpack('C')[0]
        raise 'Unexpected type: Not block data' if type != 0x77 # TC_BLOCKDATA

        blen = @input.read(1).unpack('C')[0]
        bdata = @input.read(blen)
        bdata
      end

      def skip_custom
        loop do
          type = @input.read(1).unpack('C')[0]
          if type == 0x77
            blen = @input.read(1).unpack('C')[0]
            @input.read(blen)
          elsif type == 0x78
            return
          else
            read_object_type(type)
          end
        end
      end

      def read_object
        data = @input.read(1)
        return if data.nil?
        type = data.unpack('C')[0]
        read_object_type(type)
      end

      def read_object_type(type)
        if type == 0x70
          nil
        elsif type == 0x71
          read_handle
        elsif type == 0x72
          read_class_desc(type)
        elsif type == 0x73
          read_ordinary_object
        elsif type == 0x74
          read_string_type(type)
        elsif type == 0x75
          read_array
        elsif type == 0x7b
          read_exception
        else
          raise 'Unsupported object type ' + type.to_s(16)
        end
      end

      def defaultReadObject(desc)
        read_object_fields(desc)
      end

      def read_object_fields(desc)
        fields = {}
        for pf in desc[3]
          t = pf[1]
          if t == 'J' || t == 'D'
            val = @input.read(8)
          elsif t == 'I' || t == 'F'
            val = @input.read(4)
          elsif t == 'C' || t == 'S'
            val = @input.read(2)
          elsif t == 'B' || t == 'Z'
            val = @input.read(1)
          else
            raise 'Invalid value type ' + t.to_s
          end
          fields[pf[0]] = val
        end

        for of in desc[4]
          val = read_object
          fields[of[0]] = val
        end
        fields
      end

      def read_ordinary_object
        desc = read_class_desc
        obj = [desc, nil]
        @handles.push(obj)
        flags = desc[2]
        if flags & 0x8 == 0x8
          raise 'Externalizable'
        else
          fields = {}
          obj[1] = fields

          chain = []
          cur = desc
          begin
            chain.insert(0, cur)
            cur = cur[5]
          end while !cur.nil?

          for cdesc in chain
            tstr = 'L' + cdesc[0].tr('.', '/') + ';'
            sdesc = @registry.getDescriptor(tstr)
            if !sdesc.nil? && sdesc.fetch('hasReadObject', false)
              read = @registry.getHandler(tstr).readObject(self, cdesc)
              fields.merge!(read) unless read.nil?
            else
              fields.merge!(read_object_fields(cdesc))
            end

            skip_custom if cdesc[2] & 0x01 == 0x01
          end
        end
        obj
      end

      def read_exception
        ex = read_object
        raise DeserializeException, ex
      end

      def read_array
        desc = read_class_desc
        len = @input.read(4).unpack('I>')[0]
        values = []
        @handles.push(values)

        for i in 0..len - 1
          values.push(read_object)
        end

        values
      end

      def read_class_desc
        type = @input.read(1).unpack('C')[0]
        read_class_desc_type(type)
      end

      def read_class_desc_type(type)
        if type == 0x70
          nil
        elsif type == 0x71
          read_handle
        elsif type == 0x72
          name = read_utf
          suid, flags, nfields = @input.read(11).unpack('Q>CS>')

          primfields = []
          objfields = []
          desc = [name, suid, flags, primfields, objfields, nil]
          @handles.push(desc)
          for i in 0..nfields - 1
            tcode = @input.read(1)[0]
            fname = read_utf
            if tcode == 'L' || tcode == '['
              tname = read_string
              objfields.push([fname, tname])
            else
              primfields.push([fname, tcode])
            end
          end

          skip_custom
          desc[5] = read_class_desc
          desc
        elsif type == 0x7d
          intfs = []
          desc = ['proxy', 0, 0, [], [], nil, intfs]
          @handles.push(desc)
          nintf = @input.read(4).unpack('L>')[0]
          for i in 0..nintf - 1
            intfs[i] = read_utf
          end
          skip_custom
          desc[5] = read_class_desc
          desc
        else
          raise 'Not a class descriptor ' + type.to_s(16)
        end
      end
    end
  end
end
