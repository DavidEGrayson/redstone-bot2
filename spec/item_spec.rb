require 'redstone_bot/protocol/item'

describe RedstoneBot::Item do
  it "matches spots that hold the same item" do
    item = RedstoneBot::ItemType::Wood * 1
    spot = RedstoneBot::Spot.new(RedstoneBot::ItemType::Wood * 1)
    item.should === spot
  end
  
  it "encodes and reads some dummy data correctly" do
    item0 = described_class.new(RedstoneBot::ItemType::Bow, 1, 9, "foofoo")
    item = described_class.receive_data test_stream item0.encode_data    
    item.should == item0
  end
  
  it "reads enchant data correctly" do
    binary_data = "\x01\x02\x01\x00\x0C\x00\x37" +
      "\x1F\x8B\x08\x00\x00\x00\x00\x00\x00\x00\xE3\x62\x60\x2E\x49\x4C\xE7\x64\x60" +
      "\x49\xCD\x4B\xCE\xE0\x62\x60\x60\x60\x64\x62\x60\xCA\x4C\x61\x50\x62\x62\x60" +
      "\xCE\x29\xCB\x61\x60\x64\x60\x00\x00\x69\xB7\x3B\x24\x23\x00\x00\x00"
    
    item = described_class.receive_data test_stream binary_data
    
    item.item_type.should == RedstoneBot::ItemType::IronAxe
    item.damage.should == 12
    item.enchant_data.should == "\x0A\x00\x03\x74\x61\x67\x09\x00\x04\x65\x6E\x63\x68\x0A\x00" +
      "\x00\x00\x01\x02\x00\x02\x69\x64\x00\x22\x02\x00\x03\x6C\x76\x6C\x00\x01\x00\x00"
    
    # \x0A \x00\x03 tag
     # \x09 \x00\x04 ench
     # \x0A \x00\x00\x00\x01
       # \x02 \x00\x02 id \x00\x22
       # \x02 \x00\x03 lvl \x00\x01
       # \x00
    # \x00
    
  end
end