# coding: utf-8

require_relative 'spec_helper'
require 'redstone_bot/protocol/pack'

shared_examples_for "equates" do |name, nbt, data|
  it "correctly decodes #{name}" do
    test_stream(nbt).read_nbt.should == data
  end
  
  it "correctly encodes #{name}" do
    encoder.nbt(data).should == nbt.force_encoding("BINARY")
  end  
end

shared_examples_for "decodes" do |name, nbt, data|
  it "correctly decodes #{name}" do
    test_stream(nbt).read_nbt.should == data
  end  
end

describe "nbt" do

  it_behaves_like "equates", "empty compound", "\x0A\x00\x03tag\x00", { "tag" => {} }
  
  it_behaves_like "equates", "byte", "\x01\x00\x01b\x10", { "b" => 16 }
  it_behaves_like "equates", "short", "\x02\x00\x01s\xFE\xD4", { "s" => -300 }
  
  # Some real enchant data from the server.
  data = "\x0A\x00\x03\x74\x61\x67\x09\x00\x04\x65\x6E\x63\x68\x0A\x00" +
    "\x00\x00\x01\x02\x00\x02\x69\x64\x00\x22\x02\x00\x03\x6C\x76\x6C\x00\x01\x00\x00"
  it_behaves_like "decodes", "enchant data", data, { "tag" => { "ench" => [{"id"=>34, "lvl"=>1}]} }

  context "floats" do
    # TODO: test these:
    { "float" => -400.3,    # gets encoded as a double
         "double" => 1.991,
         "list_of_doubles" => [0, 1.3, 44] }
  end  
end

describe "nbt" do
  context "big test" do
    let(:data) do
      {  "byte1" => 1,
         "byte2" => -128,
         "short1" => 256,
         "short2" => -19041,
         "int1" => 100000,
         "long" => 2**32 + 5,
         "byte_array" => "\x00\xFF".force_encoding("BINARY"),
         "string" => "✓UTF-8",
         "list_of_bytes" => [1, 2, 3],
         "list_of_shorts" => [1, 1000, 0],
         "list_of_ints" => [0, -100000, 1],
         "list_of_longs" => [4, 2**32+1, 44],
         "list_of_strings" => ["hello", "world"],
         "list_of_lists" => [[1,2], ["a", "b"]],
         "compound" => { "int1" => 400000, "q" => [1, 2, 3] },
         "int_array" => "???????" # TODO: how to represent int arrays
      }
    end
  end
end