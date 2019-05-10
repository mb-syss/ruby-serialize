
module Java
  module Serialize
    module Data
      class JavaPrimitive
        attr_accessor :value
        def initialize(value)
          @value = value
        end
      end

      class JavaBoolean < JavaPrimitive
      end

      class JavaByte < JavaPrimitive
      end

      class JavaShort < JavaPrimitive
      end

      class JavaChar < JavaPrimitive
      end

      class JavaInteger < JavaPrimitive
      end

      class JavaLong < JavaPrimitive
      end

      class JavaFloat < JavaPrimitive
      end

      class JavaDouble < JavaPrimitive
      end

      class DataOutputStream
        def initialize(io)
          @io = io
        end

        def write(bytes)
          @io.write(bytes)
        end

        def writeBoolean(b)
          @io.write(b ? '\1' : '\0')
        end

        def writeByte(b)
          @io.write([b].pack('c'))
        end

        def writeShort(s)
          @io.write([s].pack('s>'))
        end

        def writeChar(c)
          @io.write([c].pack('S>'))
        end

        def writeInt(i)
          @io.write([i].pack('i>'))
        end

        def writeLong(l)
          @io.write([l].pack('q>'))
        end

        def writeFloat(_f)
          raise NotImplementedError
        end

        def writeDouble(_d)
          raise NotImplementedError
        end

        def writeBytes(s)
          # is this right?
          data = s.encode(Encoding::UTF_16BE).each_char.map { |c| (c.ord & 0xFF).chr }.join.force_encoding('BINARY')
          @io.write(data)
        end

        def writeChars(s)
          data = s.encode(Encoding::UTF_16BE).force_encoding('BINARY')
          @io.write(data)
        end
      end
    end
  end
end
