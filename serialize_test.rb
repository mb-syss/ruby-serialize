
require_relative 'serialize'
require 'test/unit'

class TestObjectOutput < Test::Unit::TestCase
  def get_registry
    reg = Registry.new
    reg.register('java.nio.file.AccessMode', 'superType' => 'Ljava/lang/Enum;', 'enum' => true)
    reg.register('java.lang.Throwable', 'serialVersion' => -3_042_686_055_658_047_285, 'hasWriteObject' => false, 'fields' => [
                   { 'name' => 'detailMessage', 'typeString' => 'Ljava/lang/String;' }
                 ])

    reg.register('java.util.concurrent.atomic.AtomicInteger', 'serialVersion' => 6_214_790_243_416_807_050,
                                                              'fields' => [{ 'name' => 'value', 'typeString' => 'I' }],
                                                              'superType' => 'Ljava/lang/Number;')

    reg.register('java.lang.Number', 'serialVersion' => -8_742_448_824_652_078_965)
    reg
  end

  def test_magic
    buf = StringIO.new('', 'wb+')
    oos = ObjectOutputStream.new(buf, get_registry)
    assert_equal([0xAC, 0xED, 0x00, 0x05], buf.string.each_byte.to_a)
  end

  def test_write_string_obj
    buf = StringIO.new('', 'wb+')
    oos = ObjectOutputStream.new(buf, get_registry)

    oos.writeObject('test')

    ar = buf.string.each_byte.to_a

    assert_equal(0x74, ar[4])
    assert_equal([0x0, 0x4], ar[5..6])
    assert_equal(11, ar.length)
  end

  def test_write_string_ref
    buf = StringIO.new('', 'wb+')
    oos = ObjectOutputStream.new(buf, get_registry)

    s = 'test'

    oos.writeObject(s)
    oos.writeObject(s)

    ar = buf.string.each_byte.to_a

    assert_equal(0x74, ar[4])
    assert_equal([0x0, 0x4], ar[5..6])

    dat = ar[7..10]
    assert_equal(0x71, ar[11])

    hdl = ar[12..16]

    assert_equal([0x00, 0x7e, 0x00, 0x00], hdl)
  end

  def test_write_enum
    buf = StringIO.new('', 'wb+')
    oos = ObjectOutputStream.new(buf, get_registry)
    oos.writeObject(JavaEnum.new('Ljava/lang/Enum;', 'test'))
  end

  def test_write_enum2
    buf = StringIO.new('', 'wb+')
    oos = ObjectOutputStream.new(buf, get_registry)
    oos.writeObject(JavaEnum.new('Ljava/nio/file/AccessMode;', 'READ'))
  end

  def test_write_class
    buf = StringIO.new('', 'wb+')
    oos = ObjectOutputStream.new(buf, get_registry)
    oos.writeObject(JavaClass.new('Ljava/nio/file/AccessMode;'))
  end

  def test_write_osc
    buf = StringIO.new('', 'wb+')
    oos = ObjectOutputStream.new(buf, get_registry)
    oos.writeObject(ObjectStreamClass.new('Ljava/nio/file/AccessMode;'))
  end

  def test_write_prim_arrays
    buf = StringIO.new('', 'wb+')
    oos = ObjectOutputStream.new(buf, get_registry)
    oos.writeObject(JavaArray.new('S', [1, 2, 3, 4, 5]))
    oos.writeObject(JavaArray.new('Z', [1, 2, 3, 4, 5]))
    oos.writeObject(JavaArray.new('B', [1, 2, 3, 4, 5]))
    oos.writeObject(JavaArray.new('J', [1, 2, 3, 4, 5]))
    oos.writeObject(JavaArray.new('I', [1, 2, 3, 4, 5]))
  end

  def test_write_2dim_prim_arrays
    buf = StringIO.new('', 'wb+')
    oos = ObjectOutputStream.new(buf, get_registry)
    oos.writeObject(JavaArray.new('[S', [JavaArray.new('S', [1, 2]), JavaArray.new('S', [3, 4])]))
  end
end
