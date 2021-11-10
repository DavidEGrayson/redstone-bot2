require_relative 'spec_helper'
require 'redstone_bot/protocol/item_types'

describe RedstoneBot::ItemType do
  it "can flexibly figure out what block type you want" do
    glass = RedstoneBot::ItemType::Glass
    expect(described_class.from("glass")).to eq(glass)
    expect(described_class.from("20")).to eq(glass)
    expect(described_class.from("0x14")).to eq(glass)
    expect(described_class.from(20)).to eq(glass)
    expect(described_class.from(nil)).to eq(nil)
    expect(described_class.from("nil")).to eq(nil)
    expect(described_class.from("diamond")).to eq(RedstoneBot::ItemType::Diamond)
    expect(described_class.from("diamond ore")).to eq(RedstoneBot::ItemType::DiamondOre)
  end
  
  it "has items also" do
    expect(described_class.from(256)).to eq(RedstoneBot::ItemType::IronShovel)
  end
  
  it "avoids ambiguous names" do
    names = described_class.instance_variable_get(:@types_by_string).keys
    expect(names.size).to be > 100
    names.each do |name|
      next if ["diamond", "emerald"].include?(name)
      expect(names).not_to include name + "block"
      expect(names).not_to include name + "item"
    end
  end
  
  it "has a nice matcher" do
    s = double("something")
    allow(s).to receive(:item_type) { RedstoneBot::ItemType::IronShovel}
    expect(RedstoneBot::ItemType::IronShovel).to be === s
    expect(RedstoneBot::ItemType::IronShovel).to be === RedstoneBot::ItemType::IronShovel
    expect(RedstoneBot::ItemType::IronShovel).to be === RedstoneBot::Item.new(RedstoneBot::ItemType::IronShovel, 44, 1, nil)
    expect(RedstoneBot::ItemType::WheatItem).to be === RedstoneBot::Item.new(RedstoneBot::ItemType::WheatItem)
  end
  
  it "tells you if it is a block or not" do
    expect(RedstoneBot::ItemType::DiamondOre).to be_block
    expect(RedstoneBot::ItemType::Diamond).not_to be_block
  end
  
  it "tells you if it is solid or not" do
    expect(RedstoneBot::ItemType::CoalOre).to be_solid
    expect(RedstoneBot::ItemType::WheatBlock).not_to be_solid
  end
  
  it "tells you how stackable items are" do
    expect(RedstoneBot::ItemType::CoalOre.max_stack).to eq(64)
    expect(RedstoneBot::ItemType::SignPost.max_stack).to eq(16)
    expect(RedstoneBot::ItemType::IronShovel.max_stack).to eq(1)
  
    expect(RedstoneBot::ItemType::SignPost).to be_stackable
    expect(RedstoneBot::ItemType::IronShovel).not_to be_stackable
  end
end