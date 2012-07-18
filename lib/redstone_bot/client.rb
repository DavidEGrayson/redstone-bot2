require "redstone_bot/pack"
require "redstone_bot/packets"
require "redstone_bot/synchronizer"

require 'socket'
require 'io/wait'
require 'thread'
require 'net/https'
require 'net/http'
require 'uri'

Thread.abort_on_exception = true

module RedstoneBot
  class Client
    include Synchronizer
  
    attr_reader :socket
    attr_reader :username
    attr_reader :hostname
    attr_reader :port
    attr_reader :eid
    
    def initialize(username, password, hostname, port)
      @username = username
      @password = password
      @hostname = hostname
      @port = port
      @listeners = []
      @connected = false
      
      listen { |packet| handle_packet(packet) }
    end
    
    # Called at setup time.
    def listen(&proc)
      @listeners << proc
    end
    
    def notify_listeners(*args)
      synchronize do
        @listeners.each do |l|
          l.call(*args)
        end
      end
    end
    
    # http://www.wiki.vg/Authentication
    def login   
      # Attempt 3
      uri = URI.parse("https://login.minecraft.net/")
      puts "port = #{uri.port}"
      http = Net::HTTP.new("login.minecraft.net", 443)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      postdata = "user=#{username}&password=#{@password}&version=<launcher version>"
      puts "postdata = #{postdata}"
      resp, data = http.post("/", postdata, 'Content-Type' => 'application/x-www-form-urlencoded')
      puts "1", resp, "2", data, "3", resp.body
      exit
      
      #http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Post.new("login.minecraft.net", 443)
      request.content_type = 'application/x-www-form-urlencoded'
      request.set_form_data('username' => username, 'password' => @password, 'version' => 999)

      puts "requesting login..."
      http.post("https://login.minecraft.net/")
      #response = http.request(request)
      puts "RESPONSE: "
      puts response.body
      puts response.status
    
      # Attempt 1
      #uri = URI("https://login.minecraft.net")
      #res = Net::HTTP.post_form(uri, 'user' => username, 'password' => @password, 'version' => 999)
            

      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        puts "OK!"
      else
        puts "value = #{res.value}"
      end
      
      puts "Received from #{uri.host}:"      
      puts res.body
      
    end
    
    def start
      login if @password
      exit # tmphax
    
      @mutex = Mutex.new    
      @socket = TCPSocket.open hostname, port
      @socket.extend DataReader
      
      send_packet Packet::Handshake.new(username, hostname, port)
      receive_packet
      
      send_packet Packet::LoginRequest.new(username)
      received_packet = receive_packet
      if received_packet.is_a? RedstoneBot::Packet::Disconnect
        puts "Login refused with reason: #{received_packet.reason}"
        exit
      end
      @eid = received_packet.eid
      
      @connected = true
      notify_listeners :start
      
      # Receive packets
      Thread.new do
        begin
          while true
            packet = receive_packet
            #puts packet.inspect   # tmphax
            notify_listeners packet
          end
        rescue UnknownPacketError => e
          error_message = "WHAT'S 0x%02X PRECIOUSSS?" % [e.packet_type]
          chat error_message
          abort error_message
        end
      end
      
      # Send keepalives
      regularly(1) do
        send_packet Packet::KeepAlive.new
      end
      
    end
    
    def receive_packet
      Packet.receive(socket)
    end
    
    def send_packet(packet)
      socket.write packet.encode
    end
    
    def chat(message)
      send_packet Packet::ChatMessage.new(message) 
    end
    
    def handle_packet(p)
      case p
      when Packet::Disconnect
        puts "#{self} was disconnected by server: #{p.reason}"
        @connected = false
      end
    end
    
    def connected?
      @connected
    end
  end
end