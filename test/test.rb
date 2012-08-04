require_relative "test_helper"
require "redstone_bot/client"
require_relative "config"

if ARGV.empty?
  puts "Usage: test.rb BotClassName"
  exit 1
end

bot_name = ARGV[0]
require "redstone_bot/bots/" + bot_name.underscore
bot_class = RedstoneBot::Bots.const_get bot_name.intern

puts "Starting #{bot_class}..."

client = RedstoneBot::Client.new(USERNAME, PASSWORD, HOSTNAME, PORT)
bot = bot_class.new(client)
bot.start_bot
while true
  sleep 10
end