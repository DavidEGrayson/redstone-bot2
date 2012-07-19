require_relative "test_helper"
require "redstone_bot/client"
require "redstone_bot/bots/david_bot"
require_relative "config"

client = RedstoneBot::Client.new(USERNAME, PASSWORD, HOSTNAME, PORT)
bot = RedstoneBot::Bots::DavidBot.new(client)
bot.start
while true
  sleep 10
end