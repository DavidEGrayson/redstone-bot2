class TestBody < RedstoneBot::Body
  def start_position_updater
    # In production, we run a thread that regularly updates the position.
    # In tests, we just run body.position_update to simulate the action of that thread.
  end
end