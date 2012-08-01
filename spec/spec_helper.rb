$LOAD_PATH.unshift File.join File.dirname(__FILE__), '..', 'lib'

require_relative 'test_client'
require_relative 'packet_create'
require 'stringio'

def test_stream(string)
  stream = StringIO.new(string)
  stream.extend RedstoneBot::DataReader
end

# monkeypatch to make tests more readable
class RedstoneBot::ItemType
  def *(count)
    raise ArgumentError.new("count must be an integer larger then 0") unless count > 0
    RedstoneBot::Slot.new(self, count)
  end
end