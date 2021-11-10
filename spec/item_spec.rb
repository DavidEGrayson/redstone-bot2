# coding: ASCII-8BIT

require 'redstone_bot/models/item'

# TODO: remove this after we figure out the gzip problem
describe "basic problem with Ruby's GZipWriter" do
  it "does not let you set mtime to 0" do
    sio = StringIO.new
    writer = Zlib::GzipWriter.new(sio)
    writer.mtime = 0
    writer.write "hello world"
    writer.close
    gzdata = sio.string
  
    reader = Zlib::GzipReader.new(StringIO.new gzdata)
    expect(reader.mtime.to_i).to be_within(1).of(Time.now.to_i)
  end
  
  it "can be worked around by modifying the gzip header" do
    sio = StringIO.new
    writer = Zlib::GzipWriter.new(sio)
    writer.write "hello world"
    writer.close
    gzdata = sio.string
    gzdata[4..7] = "\x00\x00\x00\x00"
  
    reader = Zlib::GzipReader.new(StringIO.new gzdata)
    expect(reader.mtime.to_i).to eq(0)
  end 
end

describe RedstoneBot::Item do
  it "matches spots that hold the same item" do
    item = RedstoneBot::ItemType::Wood * 1
    spot = RedstoneBot::Spot.new(RedstoneBot::ItemType::Wood * 1)
    expect(item).to be === spot
  end
  
  it "encodes and reads some dummy data correctly" do
    item0 = described_class.new(RedstoneBot::ItemType::Bow, 1, 9, { :infinity => 15000, :fire_aspect => -4 })
    item = test_stream($e.encode_item(item0)).read_item
    expect(item).to eq(item0)
  end

  context "given an enchanted axe" do
    let (:binary_data) do
      "\x01\x02" +   # item type = IronAxe
      "\x01\x00" +   # count = 1
      "\x0C" +       # damage = 12
      "\x00\x37" +   # nbt length
      "\x1F\x8B\x08\x00\x00\x00\x00\x00\x00\x00\xE3\x62\x60\x2E\x49\x4C\xE7\x64\x60" +
      "\x49\xCD\x4B\xCE\xE0\x62\x60\x60\x60\x64\x62\x60\xCA\x4C\x61\x50\x62\x62\x60" +
      "\xCE\x29\xCB\x61\x60\x64\x60\x00\x00\x69\xB7\x3B\x24\x23\x00\x00\x00"
    end

    before do
      @item = test_stream(binary_data).read_item
    end
    
    specify { expect(@item.item_type).to eq(RedstoneBot::ItemType::IronAxe) }
    specify { expect(@item.damage).to eq(12) }
    specify { expect(@item.enchantments).to eq({ unbreaking: 1 }) }    
    specify { expect(@item.to_s).to eq("IronAxe(damage=12 unbreaking=1)") }
    
    it "re-encodes the same way" do
      expect($e.encode_item(@item)).to eq(binary_data) 
    end
  end
end