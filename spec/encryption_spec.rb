require "spec_helper"
require "redstone_bot/packets"
require "redstone_bot/client"
require "stringio"

describe RedstoneBot::EncryptionStream do
  before do
    @writeable = StringIO.new
    @writeable.set_encoding "ASCII-8BIT"
    iv = "\x44\xAA"*8
    @enc_stream = RedstoneBot::EncryptionStream.new(@writeable, iv)    
  end
  
  it "works" do
    @enc_stream.write "hey there"
    @writeable.string.should == "\x73\x83\x80\x83\x08\x35\x2D\xDF\xE3"
  end
end

describe "EncryptionStream and DecryptionStream" do
  before do
    iv = "\x44\xAA"*8
    writeable, readable = socket_pair
    @enc_stream = RedstoneBot::EncryptionStream.new(writeable, iv)
    @dec_stream = RedstoneBot::DecryptionStream.new(readable, iv)
  end
  
  it "work together" do
    packet = "David"*100
    @enc_stream.write packet
    @dec_stream.read(packet.size).should == packet
  end
end