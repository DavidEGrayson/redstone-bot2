require 'redstone_bot/regular_updater'

class TestRegularUpdater < RedstoneBot::RegularUpdater
  def start_thread
    update_periods
  end
  
  def update
    proc.call
    update_periods
  end
end