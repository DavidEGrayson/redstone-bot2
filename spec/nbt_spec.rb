require_relative 'spec_helper'
require 'redstone_bot/protocol/pack'

describe :read_nbt do
  it "correctly reads an empty compound" do
    test_stream("\x0A\x00\x03tag\x00").read_nbt.should == { "tag" => {} }
  end
  
  it "correctly reads some enchant data" do
    data = "\x0A\x00\x03\x74\x61\x67\x09\x00\x04\x65\x6E\x63\x68\x0A\x00" +
      "\x00\x00\x01\x02\x00\x02\x69\x64\x00\x22\x02\x00\x03\x6C\x76\x6C\x00\x01\x00\x00"
  
    test_stream(data).read_nbt.should == { "tag" => { "ench" => [{"id"=>34, "lvl"=>1}]} }
  end

end