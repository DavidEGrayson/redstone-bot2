require_relative 'spec_helper'
require 'redstone_bot/trackers/window_tracker'

describe RedstoneBot::WindowTracker do
  include WindowSpecHelper

  subject { RedstoneBot::WindowTracker.new(TestClient.new) }
  let(:client) { subject.instance_variable_get(:@client) }
  let(:window_tracker) { subject}
      
  shared_examples_for "no windows are open" do
    it "has no chest model" do
      expect(subject.chest_spots).not_to be
    end
  
    it "has just one open window (inventory)" do
      expect(subject.windows.size).to eq(1)
    end
  end

  
  it "ignores random other packets" do
    subject << RedstoneBot::Packet::KeepAlive.new
  end
  
  context "initially" do
    it_behaves_like "no windows are open"
    
    it "has an inventory window" do
      expect(subject.inventory_window).to be_a RedstoneBot::InventoryWindow
    end
    
    it "has a nil inventory" do
      expect(subject.inventory).to be_nil
    end
    
    it "has no usable window" do
      expect(subject.usable_window).to be_nil
    end
    
    it { is_expected.not_to be_rejected }
  end

  context "loading an inventory" do
    let (:items) do
      [nil]*43 + [ RedstoneBot::ItemType::Melon * 2, RedstoneBot::ItemType::MushroomSoup * 2 ]
    end
    
    it "is done after the cursor has been set, and we ignore redundant SetSlot packets afterwards" do
      inventory_window = subject.inventory_window
    
      subject << RedstoneBot::Packet::SetWindowItems.create(0, items)
      expect(subject.inventory).not_to be
      
      subject << RedstoneBot::Packet::SetSlot.create(-1, -1, nil)  # set the cursor
      expect(subject.inventory).to be
      expect(subject.usable_window).to eq(subject.inventory_window)
      
      # The server will actually send packets after this, but they are redundant so we just ignore
      # them at a low level in WindowTracker.
      subject.inventory_window.spots[43].item = nil
      subject.inventory_window.spots[44].item = nil
      subject << RedstoneBot::Packet::SetSlot.create(0, 43, RedstoneBot::ItemType::Melon * 2)
      subject << RedstoneBot::Packet::SetSlot.create(0, 44, RedstoneBot::ItemType::MushroomSoup * 2)
      expect(subject.inventory_window.spots[43]).to be_empty
      expect(subject.inventory_window.spots[44]).to be_empty
      
      # But if they send a non-redundant packet then we start paying attention.
      subject << RedstoneBot::Packet::SetSlot.create(0, 43, RedstoneBot::ItemType::Melon * 20)
      expect(subject.inventory_window.spots[43].item).to eq(RedstoneBot::ItemType::Melon * 20)
    end
  end
  
  context "after a OpenWindow packet for a chest is received" do
    let(:window_id) { 2 }
    
    before do
      server_open_chest(window_id)
    end

    it "has an open ChestWindow" do
      expect(subject.windows[1]).to be_a RedstoneBot::ChestWindow
    end
    
    it "has an open ChestWindow with 27 chest_spots" do
      expect(subject.windows[1].chest_spots.size).to eq(27)
    end
    
    it "doesn't have a chest model yet" do
      expect(subject.chest_spots).to eq(nil)
    end
    
    it "has no usable window (waiting for chest to load)" do
      expect(subject.usable_window).to be_nil
    end
  end
  
  context "after a double chest is loaded" do
    let(:window_id) { 2 }
    let(:items) do
      chest = [RedstoneBot::ItemType::Stick*64] + [nil]*52 + [RedstoneBot::ItemType::WoodenPlanks*64]
      inventory = [nil]*36
      chest + inventory
    end
    
    before do
      server_open_window window_id, 0, "container.chestDouble", 54
      server_load_window window_id, items
    end
    
    it "has a chest model with 54 spots" do
      expect(subject.chest_spots.size).to eq(54)
    end
    
    it "has a usuable window" do
      expect(subject.usable_window).to be_a RedstoneBot::ChestWindow
    end
    
  end

  it "responds to SetSlot packets for the cursor after SetWindowItems packets" do
    server_set_items [nil]*45
    subject << RedstoneBot::Packet::SetSlot.create(-1, -1, RedstoneBot::ItemType::RedstoneRepeater * 10)
    expect(subject.cursor_spot.item).to eq(RedstoneBot::ItemType::RedstoneRepeater * 10)
  end
  
  context "after the inventory and a double chest is loaded" do
    let(:window_id) { 7 }
    let(:chest_items) do
      [RedstoneBot::ItemType::Flint*30, RedstoneBot::ItemType::Flint*16] +
      [nil]*51 +
      [RedstoneBot::ItemType::Netherrack*64]
    end
    let (:initial_inventory) do
      inventory = RedstoneBot::Inventory.new
      inventory.hotbar_spots[0].item = RedstoneBot::ItemType::IronSword * 1
      inventory
    end
    let(:crafting_items) do
      [nil]*5
    end
    
    before do
      server_load_window 0, crafting_items + initial_inventory.spots.items      
      server_open_window window_id, 0, "container.chestDouble", 54      
      server_load_window window_id, chest_items + initial_inventory.general_spots.items
    end
    
    it "has a chest model with 54 spots" do
      expect(subject.chest_spots.size).to eq(54)
    end
    
    it "has no item on the cursor" do
      expect(subject.cursor_spot).to be_empty
    end
    
    context "after left clicking on a empty spot in the chest" do
      let (:spot) { subject.chest_spots.empty_spots.first }
      before do
        subject.left_click(spot)
      end
      
      it "the spot is still empty" do
        expect(spot).to be_empty
      end
      
      it "the cursor is still empty" do
        expect(subject.cursor_spot).to be_empty
      end
      
      it "is synced because no clicks happened" do
        expect(subject).to be_synced
      end
    end
    
    context "after left clicking on 30 Flint in the chest" do
      let(:spot) { subject.chest_spots[0] }
      before do
        subject.left_click(spot)
      end
      
      it "sent the correct ClickWindow packet" do
        packet = client.sent_packets.last
        expect(packet).to be_a RedstoneBot::Packet::ClickWindow
        expect(packet.spot_id).to eq(0)
        expect(packet.mouse_button).to eq(:left)
        expect(packet.shift).to eq(false)
        expect(packet.clicked_item).to eq(RedstoneBot::ItemType::Flint*30)
      end
      
      it "the spot is empty" do
        expect(spot).to be_empty
      end
      
      it "the cursor has 30 Flint" do
        expect(subject.cursor_spot.item).to eq(RedstoneBot::ItemType::Flint*30)
      end
      
      it { is_expected.not_to be_synced }
      it { is_expected.not_to be_rejected }
      
      context "and confirming the transaction" do
        before do
          server_confirm_transaction
        end
        
        it { is_expected.to be_synced }
        it { is_expected.not_to be_rejected }
      end
      
      context "and rejecting the transaction" do
        before do
          server_reject_transaction
        end
        
        it { is_expected.to be_rejected }
        it { is_expected.not_to be_synced }
        
        it "sends the rejection packet back to the server" do
          packet = client.sent_packets[-1]
          expect(packet).to be_a RedstoneBot::Packet::ConfirmTransaction
          expect(packet.window_id).to eq(window_id)
          expect(packet.action_number).to eq(1)
          expect(packet.accepted).to eq(false)
        end
        
        context "and setting the window items" do
          before do
            server_set_items [RedstoneBot::ItemType::Wood * 2] * 90
          end
          
          # We still need to wait for the cursor to be set
          it { is_expected.to be_rejected }
          it { is_expected.not_to be_synced }
          
          context "and setting the cursor" do
            before do
              server_set_cursor nil
            end
            
            it { is_expected.to be_synced }
            it { is_expected.not_to be_rejected }
            
            it "ignores redundant packets" do
              spot = subject.inventory.hotbar_spots[0]
              spot.item = nil
              server_set_spot spot, RedstoneBot::ItemType::Wood * 2
              expect(spot).to be_empty   # the packet was ignored
            end
            
            it "pays attention to non-redundant packets" do
              spot = subject.inventory.hotbar_spots[0]
              server_set_spot spot, RedstoneBot::ItemType::Wood * 30
              expect(spot.item).to eq(RedstoneBot::ItemType::Wood * 30)  
            end
          end
        end

      end
      
      context "and closing the window" do
        before do
          subject.close_window
        end
        
        # The chest window was out of sync but the inventory should still be in sync, I guess.
        it { is_expected.to be_synced }
      end
    end
    
    context "and another SetWindowItems packet is received" do
      before do
        subject << RedstoneBot::Packet::SetWindowItems.create(subject.usable_window.id, chest_items + initial_inventory.general_spots.items)
      end
      
      it "window is still loaded" do
        expect(subject.usable_window).to be_loaded
      end
    end
    
    context "and closed by the server" do
      before do
        server_close_window
      end
      
      it_behaves_like "no windows are open"
    end
    
    context "and closed by the client" do
      before do
        subject.close_window
      end
      
      it_behaves_like "no windows are open"
    end
    
  end
  
  #### SPECS FOR DIFFERENT KINDS OF CLICKING ####
  
  describe :left_click do
    before do
      server_load_window 0, [nil] * 45
    end

  end
  
  describe :shift_click do
    before do
      server_load_window 0, [nil] * 45
    end
    
    context "for an empty inventory" do
      before do
        subject.shift_click subject.inventory.hotbar_spots[0]
      end
      
      it "doesn't do anything" do
        expect(client.sent_packets.size).to eq(0)
        expect(subject).to be_synced
      end
    end
    
    context "on an item in the hotbar" do
      before do
        subject.inventory.general_spots[0].item = RedstoneBot::ItemType::Dirt * 64
        subject.inventory.hotbar_spots[8].item = RedstoneBot::ItemType::DiamondSword * 1
        subject.shift_click subject.inventory.hotbar_spots[8]
      end
      
      it "puts it in the first available boring spot" do
        expect(subject.inventory.normal_spots[1].item).to eq(RedstoneBot::ItemType::DiamondSword * 1)
      end
      
      it "removes it from that spot" do
        expect(subject.inventory.hotbar_spots[8]).to be_empty
      end
      
      it "sends the right packet" do
        packet = client.sent_packets.last
        expect(packet).to be_a RedstoneBot::Packet::ClickWindow
        expect(packet.window_id).to eq(0)
        expect(packet.spot_id).to eq(44)
        expect(packet.mouse_button).to eq(:left)
        expect(packet.shift).to eq(true)
        expect(packet.clicked_item).to eq(RedstoneBot::ItemType::DiamondSword * 1)
      end
    end
    
    context "on coal in the hotbar" do
      before do
        subject.inventory.normal_spots[2].item = RedstoneBot::ItemType::CoalItem * 44
        subject.inventory.normal_spots[3].item = RedstoneBot::ItemType::CoalItem * 64
        subject.inventory.normal_spots[4].item = RedstoneBot::ItemType::CoalItem * 44
        subject.inventory.normal_spots[5].item = RedstoneBot::ItemType::Dirt * 64
        
        subject.inventory.hotbar_spots[5].item = RedstoneBot::ItemType::CoalItem * 60

        @initial_coal_quantity = subject.inventory.spots.quantity(RedstoneBot::ItemType::CoalItem)
        
        subject.shift_click subject.inventory.hotbar_spots[5]
      end

      it "conserves the quantity of coal" do
        expect(subject.inventory.spots.quantity(RedstoneBot::ItemType::CoalItem)).to eq(@initial_coal_quantity)
      end
            
      it "removes it from that spot" do
        expect(subject.inventory.hotbar_spots[8]).to be_empty
      end
      
      it "distributes it first to stackable spots and then to empty spots" do
        expect(subject.inventory.normal_spots[0].item).to eq(RedstoneBot::ItemType::CoalItem * 20)
        expect(subject.inventory.normal_spots[2].item).to eq(RedstoneBot::ItemType::CoalItem * 64)
        expect(subject.inventory.normal_spots[4].item).to eq(RedstoneBot::ItemType::CoalItem * 64)
      end
    end
    
    context "on a normal spot with an almost-full hotbar" do
      before do
        subject.inventory.normal_spots[4].item = RedstoneBot::ItemType::CoalItem * 44
        
        subject.inventory.hotbar_spots.items = [RedstoneBot::ItemType::CoalItem * 64] * 9
        subject.inventory.hotbar_spots[4].item -= 1
        subject.inventory.hotbar_spots[6].item -= 2
        subject.inventory.hotbar_spots[8].item -= 3

        @initial_coal_quantity = subject.inventory.spots.quantity(RedstoneBot::ItemType::CoalItem)
        
        subject.shift_click subject.inventory.normal_spots[4]
      end
      
      it "conserves the quantity of coal" do
        expect(subject.inventory.spots.quantity(RedstoneBot::ItemType::CoalItem)).to eq(@initial_coal_quantity)
      end
      
      it "removes 6 from the clicked spot" do
        expect(subject.inventory.normal_spots[4].item.count).to eq(44 - 6)
      end
      
      it "fills up the hotbar" do
        expect(subject.inventory.hotbar_spots.items).to eq([RedstoneBot::ItemType::CoalItem * 64] * 9)
      end
    end
  end
  
  #### SPECS FOR HIGH-LEVEL ITEM MANIPULATION:  swap, transfer, etc. ####
  
  describe :swap do
    let(:spot1) { subject.inventory.hotbar_spots[0] }
    let(:spot2) { subject.inventory.hotbar_spots[3] }
    
    before do
      server_load_window 0, [nil] * 45
    end

    context "for two items that not stackable" do
      before do
        spot1.item = RedstoneBot::ItemType::IronSword * 1
        spot2.item = RedstoneBot::ItemType::Flint*30
      end
      
      it "swaps" do
        subject.swap spot1, spot2
        expect([spot1.item, spot2.item]).to eq([RedstoneBot::ItemType::Flint*30, RedstoneBot::ItemType::IronSword * 1])
      end
    end
    
  end    

end