class TestBody < RedstoneBot::Body
  def start_position_updater
    # In production, we run a thread that regularly updates the position.
    # In tests, we just run body.position_update to simulate the action of that thread.
  end
  
  raise "Remove the method below" unless instance_method(:announce_received_position)
  def announce_received_position
    # Don't print that stuff in tests.
  end
end