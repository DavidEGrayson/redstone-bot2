require "redstone_bot/pack"
require "redstone_bot/packets"
require "redstone_bot/synchronizer"

require "socket"
require "io/wait"
require "thread"
require "net/https"
require "net/http"
require "openssl"
require "uri"

# TODO: fix logging in to online servers

Thread.abort_on_exception = true

module RedstoneBot
  class EncryptionStream
    def initialize(writeable, secret)
      @writeable = writeable
      @cipher = OpenSSL::Cipher::Cipher.new('AES-128-CFB8').encrypt
      @cipher.key = secret   # is this right?
      @cipher.iv = secret
    end
    
    def write(str)
      if !str.empty?
        @writeable.write @cipher.update(str)
      end
    end
    
  end
  
  class DecryptionStream
    include DataReader
  
    def initialize(readable, secret)
      @readable = readable
      @cipher = OpenSSL::Cipher::Cipher.new('AES-128-CFB8').decrypt
      @cipher.key = secret  # is this right?
      @cipher.iv = secret
    end

    def read(num_bytes)
      if num_bytes.zero?
        ""
      else
        @cipher.update @readable.read(num_bytes)
      end
    end
  end

  class Client
    include Synchronizer

    attr_reader :username
    attr_reader :hostname
    attr_reader :port
    attr_reader :eid
    attr_reader :mutex
    
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
      @last_packets = [nil]*4   # keep track of last 4 packets

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
      @rx_stream = @tx_stream = @socket = TCPSocket.open hostname, port
      @socket.extend DataReader

      # Handshake
      send_packet Packet::Handshake.new(username, hostname, port)
      
      # Get the encryption request.
      packet = receive_packet
      if !packet.is_a? Packet::EncryptionKeyRequest
        raise "Unexpected packet when handshaking: #{packet.inspect}"
      end
      @connection_hash = packet.connection_hash

      if @connection_hash != "-"
        if @password.to_s == ""
          raise "This is an online server: you must supply a password and log in to use it.."
        end

        log_in_to_minecraft
        request_join_server
      end

      # Generate shared secret, send encryption response
      public_key = OpenSSL::PKey::RSA.new(packet.public_key)
      secret = generate_shared_secret
      encrypted_secret = public_key.public_encrypt secret
      encrypted_token = public_key.public_encrypt packet.verify_token  # uses OpenSSL::PKey::RSA::PKCS1_PADDING
      
      send_packet Packet::EncryptionKeyResponse.new(encrypted_secret, encrypted_token)
      packet = receive_packet
      if !packet.is_a? Packet::EncryptionKeyResponse
        raise "Unexpected packet when handshaking: #{packet.inspect}"
      end
      if packet.shared_secret != "" || packet.verify_token_response != ""
        raise "Expected empty #{packet.class} but got #{packet.inspect}."
      end
      
      # Start up our encrypted streams.  From now on we will use these instead
      # of of reading and writing directly from the socket.
      @tx_stream = EncryptionStream.new(@socket, secret)
      @rx_stream = DecryptionStream.new(@socket, secret)      
      
      send_packet Packet::ClientStatuses.initial_spawn
      
      packet = receive_packet
      if !packet.is_a?(Packet::LoginRequest)
        raise "Expected login packet, but got #{packet.inspect}."
      end
      @eid = packet.eid
      
      # Report settings to the server.  There is some chance that the "far" render
      # distance will let us see more chunks.
      send_packet Packet::ClientSettings.new("en_US", :far, :enabled, true, 2)
      
      @connected = true
      @mutex = Mutex.new
      notify_listeners :start

      # Receive packets
      Thread.new do
        begin
          while true
            packet = receive_packet
            notify_listeners packet
          end
        rescue UnknownPacketError => e
          handle_unknown_packet(e)
        rescue
          report_last_packets
          raise
        end
      end

      # Send keepalives  # TODO: is this needed?
      regularly(1) do
        send_packet Packet::KeepAlive.new
      end

    end

    def handle_unknown_packet(e)
      error_message = "WHAT'S 0x%02X PRECIOUSSS?" % [e.packet_type]
      report_last_packets
      $stderr.puts error_message
      chat error_message
      abort
    end  

    def report_last_packets
      $stderr.puts "Last packets: #{@last_packets.inspect}"
    end
    
    def receive_packet
      packet = Packet.receive(@rx_stream)
      @last_packets.shift
      @last_packets.push packet
      packet
    end

    def send_packet(packet)
      @tx_stream.write packet.encode
      nil
    end

    def chat(message)
      send_packet Packet::ChatMessage.new(message)
    end

    def handle_packet(p)
      case p
      when Packet::KeepAlive
        send_packet p
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
    
    protected
    def generate_shared_secret
      # TODO: generate something a little more secret
      "\xAA\x44"*8
    end
  end
end