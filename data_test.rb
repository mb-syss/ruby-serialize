require_relative 'data'
require 'test/unit'

module Java
  module Serialize
    module Data
      class TestDataOutput < Test::Unit::TestCase
        def test_chars
          buf = StringIO.new('', 'wb+')
          DataOutputStream.new(buf).writeChars "fooä\u0107"

          assert_equal([0, 102, 0, 111, 0, 111, 0, 228, 1, 7], buf.string.each_byte.to_a)
        end

        def test_byte_string
          buf = StringIO.new('', 'wb+')
          DataOutputStream.new(buf).writeBytes "fooä\u0107"

          assert_equal([102, 111, 111, 228, 7], buf.string.each_byte.to_a)
        end
      end
      end
  end
end
