$LOAD_PATH.unshift File.join File.dirname(__FILE__), 'lib'
require_relative "config"

class String
  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
end

require "redstone_bot/client"
require_relative "config"

if ARGV.empty?
  puts "Usage: run.rb BotClassName"
  exit 1
end

bot_name = ARGV[0]
require "redstone_bot/bots/" + bot_name.underscore
bot_class = RedstoneBot.const_get bot_name.intern

trap("SIGINT") { exit }  # Ctrl+C cleanly kills the bot.

puts "Starting #{bot_class}..."

client = RedstoneBot::Client.new(USERNAME, PASSWORD, HOSTNAME, PORT)
bot = bot_class.new(client)
bot.start_bot
while true
  sleep 10
end