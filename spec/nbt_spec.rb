require_relative 'spec_helper'
require 'redstone_bot/protocol/pack'

describe :read_nbt do
  it "correctly reads an empty compound" do
    test_stream("\x0A\x00\x03tag\x00").read_nbt.should == [[:compound, "tag", []]]
  end
end