require_relative "spec_helper"
require "redstone_bot/packets"

describe "hax" do
  it "can make strings from hex strings" do
    String.from_hex("44:fc").should == "\x44\xFC"
  end
end