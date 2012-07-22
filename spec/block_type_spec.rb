require_relative 'spec_helper'
require 'redstone_bot/block_types'

describe RedstoneBot::BlockType do
  it "can flexibly figure out what block type you want" do
    glass = RedstoneBot::BlockType::Glass
    described_class.from("glass").should == glass
    described_class.from("20").should == glass
    described_class.from("0x14").should == glass
    described_class.from(20).should == glass
  end
end