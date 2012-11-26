require_relative 'spec_helper'

describe RedstoneBot::Wielding do
  include WindowSpecHelper

  let(:client) { @client }
  let(:bot) { @bot }
  let(:hotbar_spots) { bot.window_tracker.inventory_window.inventory.hotbar_spots }
  
  before do
    @bot = TestBot.new_at_position RedstoneBot::Coords[8, 70, 8]
    @client = @bot.client
    
    items = [nil]*45
    items[10] = RedstoneBot::ItemType::IronShovel * 1
    items[12] = RedstoneBot::ItemType::Bread * 2
    items[36] = RedstoneBot::ItemType::WheatItem * 31
    items[37] = RedstoneBot::ItemType::Bread * 44    
    server_load_window 0, items    
  end
  
  it "is set up correctly" do
    @bot.window_tracker.inventory_window.should be_loaded
    @bot.window_tracker.inventory.should be
    @bot.inventory.should be
  end
  
  it "initially the first spot in the hotbar is wielded" do
    bot.wielded_spot.should == hotbar_spots[0]
  end
  
  it "defines wielded_item" do
    bot.wielded_item.should == RedstoneBot::ItemType::WheatItem * 31
  end
  
  describe :wield do
    shared_examples_for "it succeeds trivially" do
      it "doesn't send any packets and returns true" do
        @client.should_not_receive :send_packet
        @bot.wield(wield_spec).should == true
        @bot.wielded_spot.should == hotbar_spots[0]
        @bot.window_tracker.should be_synced
      end    
    end

    shared_examples_for "it switches to the second hotbar spot" do
      it "returns true and sends one packet" do
        @client.should_receive(:send_packet).with(RedstoneBot::Packet::HeldItemChange.new(1))
        @bot.wield(wield_spec).should == true
        @bot.wielded_spot.should == hotbar_spots[1]
        @bot.window_tracker.should be_synced
      end
    end
    
    shared_examples_for "it fails" do
      it "returns false and doesn't send any packets" do
        @client.should_not_receive(:send_packets)
        @bot.wield(wield_spec).should == false
        @bot.window_tracker.should be_synced
      end
    end
    
    context "when passed the currently wielded spot" do
      let(:wield_spec) { hotbar_spots[0] }
      it_behaves_like "it succeeds trivially"
    end
    
    context "when passed the currently wielded exact item" do
      let(:wield_spec) { RedstoneBot::ItemType::WheatItem * 31 }
      it_behaves_like "it succeeds trivially"      
    end

    context "when passed the currently wielded item type" do
      let(:wield_spec) { RedstoneBot::ItemType::WheatItem }
      it_behaves_like "it succeeds trivially"
    end
    
    context "when passed another spot in the hotbar" do
      let(:wield_spec) { hotbar_spots[1] }
      it_behaves_like "it switches to the second hotbar spot"
    end
    
    context "when passed the number 1" do
      let(:wield_spec) { 1 }
      it_behaves_like "it switches to the second hotbar spot"    
    end
    
    context "when passed the item type of the second hotbar spot" do
      let(:wield_spec) { hotbar_spots[1].item_type }
      it_behaves_like "it switches to the second hotbar spot"
    end
    
    context "when passed the exact item of the second hotbar spot" do
      let(:wield_spec) { hotbar_spots[1].item }
      it_behaves_like "it switches to the second hotbar spot"    
    end

    context "when passed an item type that is not in the inventory" do
      let(:wield_spec) { RedstoneBot::ItemType::Melon }
      it_behaves_like "it fails"
    end

    context "when passed an item type not in the hotbar" do
      let(:wield_spec) { RedstoneBot::ItemType::IronShovel }
      it "swaps two spots" do
        @client.should_receive(:send_packet).exactly(3).times # left click, left click, change held item
        @bot.wield(wield_spec).should == true
        @bot.wielded_spot.should == hotbar_spots[2]
        @bot.wielded_item.should == RedstoneBot::ItemType::IronShovel * 1
        @bot.window_tracker.should_not be_synced
      end
    end
    
    context "when passed an item type not in the hotbar and the hotbar is full" do
      let(:wield_spec) { RedstoneBot::ItemType::IronShovel }
    
      before do
        hotbar_spots.items = [ RedstoneBot::ItemType::Wool * 64 ] * 9
      end
      
      it "swaps two spots" do
        @client.should_receive(:send_packet).exactly(3).times # left click, left click, left click
        @bot.wield(wield_spec).should == true
        @bot.window_tracker.should_not be_synced
      end
    end
    
    context "when passed nil and the hotbar is full" do
      let(:wield_spec) { nil }
    
      before do
        hotbar_spots.items = [ RedstoneBot::ItemType::Wool * 64 ] * 9
      end
      
      it "moves an item out of the hotbar" do
        @client.should_receive(:send_packet).exactly(2).times # left click, left click
        @bot.wield(wield_spec).should == true
        @bot.window_tracker.should_not be_synced      
      end
    end
    
    context "when passed nil and the inventory is full" do
      let(:wield_spec) { nil }
    
      before do
        @bot.inventory.general_spots.items = [ RedstoneBot::ItemType::Wool * 64 ] * 36        
      end
      
      it_behaves_like "it fails"
    end
    
  end
  
  describe :wielded_item_drop do
    it "just sends the right PlayerDigging packet" do
      @bot.wielded_item_drop
      packet = @client.sent_packets.last
      packet.should be_a RedstoneBot::Packet::PlayerDigging
    end
  end
  
end