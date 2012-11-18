require 'redstone_bot/regular_updater'

class TestRegularUpdater < RedstoneBot::RegularUpdater
  def start_thread
    update_periods
  end
  
  def update
    update_periods
    proc.call
  end
end