$LOAD_PATH.unshift File.join File.dirname(__FILE__), '..', 'lib'
$LOAD_PATH.unshift File.join File.dirname(__FILE__), '..', 'test'

require 'test_client'
require 'packet_create'
require 'test_bot'

require 'stringio'

def test_stream(string)
  stream = StringIO.new(string)
  stream.extend RedstoneBot::DataReader
end

def socket_pair
  Socket.pair(:UNIX, :STREAM)   # works in Linux
rescue Errno::EAFNOSUPPORT
  Socket.pair(:INET, :STREAM)   # works in Windows
end

RSpec.configure do |c|
  c.alias_it_should_behave_like_to :it_has_behavior, 'has behavior:'
end

module WindowSpecHelper
  def server_open_window(*args)
    client << RedstoneBot::Packet::OpenWindow.create(*args)
  end
  
  def server_set_spot(spot, item)
    window = window_tracker.windows.last
    spot_id = window.spot_id(spot)
    client << RedstoneBot::Packet::SetSlot.create(window.id, spot_id, item)
  end
   
  def server_set_cursor(item)
    client << RedstoneBot::Packet::SetSlot.create(-1, -1, item)
  end
  
  def server_set_items(items)
    window = window_tracker.windows.last
    client << RedstoneBot::Packet::SetWindowItems.create(window.id, items)
  end
  
  def server_load_window(window_id, items, cursor_item=nil)
    client << RedstoneBot::Packet::SetWindowItems.create(window_id, items)
    client << RedstoneBot::Packet::SetSlot.create(-1, -1, cursor_item)
    
    # These packets get ignored:
    items.each_with_index do |item, spot_id|
      client << RedstoneBot::Packet::SetSlot.create(window_id, spot_id, item) if item
    end
  end
  
  # This is what the server does after a transaction is rejected.
  # It sends the packets in THIS order, which is kind of inconvenient.
  def server_reload_window(items, cursor_item=nil)
    server_set_items items
    server_set_cursor cursor_item
  end
  
  def server_close_window(window_id=nil)
    client << RedstoneBot::Packet::CloseWindow.create(subject.windows[1].id)
  end
  
  def server_transaction_decision(confirm)
    window = window_tracker.windows.last
    transaction_id = window.pending_actions.first
    client << RedstoneBot::Packet::ConfirmTransaction.new(window.id, transaction_id, confirm)
  end

  def server_confirm_transaction
    server_transaction_decision true
  end
  
  def server_reject_transaction
    server_transaction_decision false
  end

end