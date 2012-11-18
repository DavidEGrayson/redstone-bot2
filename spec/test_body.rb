class TestBody < RedstoneBot::Body
  
  raise "Remove the method below" if !instance_method(:announce_received_position)
  def announce_received_position(packet)
    # Don't print that stuff in tests.
  end
end