$LOAD_PATH.unshift File.join File.dirname(__FILE__), '..', 'lib'
$LOAD_PATH.unshift File.join File.dirname(__FILE__), '..', 'test'

require 'test_client'
require 'packet_create'
require 'test_bot'

require 'stringio'

def test_stream(string)
  stream = StringIO.new(string)
  stream.extend RedstoneBot::DataReader
end

def socket_pair
  Socket.pair(:UNIX, :STREAM)   # works in Linux
rescue Errno::EAFNOSUPPORT
  Socket.pair(:INET, :STREAM)   # works in Windows
end

# monkeypatch to make tests more readable
class RedstoneBot::ItemType
  def *(count)
    raise ArgumentError.new("count must be an integer larger then 0") unless count > 0
    RedstoneBot::Slot.new(self, count)
  end
end