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
      @session_id = nil
      @connection_hash = nil
      
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
    
    def login   
      # http://www.wiki.vg/Authentication
      http = Net::HTTP.new("login.minecraft.net", 443)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      postdata = "user=#{username}&password=#{@password}&version=13"
      response, data = http.post("/", postdata, 'Content-Type' => 'application/x-www-form-urlencoded')
      body = response.body      
      puts "body = #{body}"
      _, _, case_correct_username, @session_id = body.split(":")
     
      if case_correct_username.upcase == @username.upcase
        @username = case_correct_username
      else
        puts "I do not understand why server thinks your username is #{case_correct_username}"
      end      
    end
    
    def login2
      puts "login2"
      # http://session.minecraft.net/game/joinserver.jsp?user=<username>&sessionId=<session id>&serverId=<server hash>
      
      http = Net::HTTP.new('session.minecraft.net')
      resp, data = http.get("/game/joinserver.jsp?user=#{username}&sessionId=#{@session_id}&serverId=#{@connection_hash}", {})
      cookie = resp.response['set-cookie']
      
      puts "1", resp, "2", data, "3", resp.body
      puts "4", Net::HTTPOK===resp
    end
    
    def start
      # Log in to minecraft.net
      login if @password
    
      # Connect
      @socket = TCPSocket.open hostname, port
      @socket.extend DataReader
      
      # Handshake
      send_packet Packet::Handshake.new(username, hostname, port)
      packet = receive_packet
      case packet
      when RedstoneBot::Packet::Handshake
        @connection_hash = packet.connection_hash
      else
        puts "Unexpected packet when handshaking: #{p}"
        exit
      end

      login2 if @password && @connection_hash.to_s != ""      

      # Log in to server
      send_packet Packet::LoginRequest.new(username)
      packet = receive_packet
      case packet
      when RedstoneBot::Packet::Disconnect
        puts "Login refused with reason: #{packet.reason}"
        exit
      when RedstoneBot::Packet::LoginRequest
        @eid = packet.eid
      else
        puts "Unexpected packet when logging in: #{p}"
        exit
      end
      
      @connected = true
      @mutex = Mutex.new
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
          # TODO: uncomment
          #error_message = "WHAT'S 0x%02X PRECIOUSSS?" % [e.packet_type]
          #chat error_message
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