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

    # password can be nil or empty for an offline server
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

    def log_in_to_minecraft
      # http://www.wiki.vg/Authentication
      http = Net::HTTP.new("login.minecraft.net", 443)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      postdata = "user=#{username}&password=#{@password}&version=999"
      response, data = http.post("/", postdata, 'Content-Type' => 'application/x-www-form-urlencoded')
      
      if !(Net::HTTPOK === response)
        raise "Request to log in to Minecraft failed.  Received response from login.minecraft.net: #{response.inspect}"
      end
      
      _, _, case_correct_username, @session_id = response.body.split(":")

      if case_correct_username.upcase == @username.upcase
        @username = case_correct_username
      else
        $stderr.puts "The server login.minecraft.net thinks your username is #{case_correct_username} instead of #{@username}."
      end
    end

    def request_join_server
      http = Net::HTTP.new('session.minecraft.net')
      response, data = http.get("/game/joinserver.jsp?user=#{username}&sessionId=#{@session_id}&serverId=#{@connection_hash}", {})
      
      if !(Net::HTTPOK === response)
        raise "Request to join server failed.  Received response from session.minecraft.net: #{response.inspect}"
      end
    end

    def start
      # Connect
      @socket = TCPSocket.open hostname, port
      @socket.extend DataReader

      # Handshake
      send_packet Packet::Handshake.new(username, hostname, port)
      packet = receive_packet
      if !packet.is_a? RedstoneBot::Packet::Handshake
        raise "Unexpected packet when handshaking: #{p}"
      end
      @connection_hash = packet.connection_hash

      if @connection_hash != "-"
        if @password.to_s == ""
          raise "This is an online server: you must supply a password and log in to use it.."
        end

        log_in_to_minecraft
        request_join_server
      end

      # Log in to server
      send_packet Packet::LoginRequest.new(username)
      packet = receive_packet
      case packet
      when RedstoneBot::Packet::Disconnect
        raise "Login refused with reason: #{packet.reason}"
      when RedstoneBot::Packet::LoginRequest
        @eid = packet.eid
      else
        raise "Unexpected packet when logging in: #{p}"
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
      nil
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
    
    def time_string
      Time.now.strftime("%M-%S-%L")
    end
    
    def next_action_number
      @last_action_number ||= 0  # cannot use an enumerator we use this cross-thread 
      if @last_action_number < 0xFFFF
        @last_action_number += 1
      else
        @last_action_number = 1
      end
    end
  end
end