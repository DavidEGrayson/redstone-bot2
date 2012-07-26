$LOAD_PATH.unshift File.join File.dirname(__FILE__), '..', 'lib'

require_relative 'test_client'
require_relative 'packet_create'
require 'stringio'

def test_stream(string)
  stream = StringIO.new(string)
  stream.extend RedstoneBot::DataReader
end