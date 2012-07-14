require "redstone_bot/pack"
require "redstone_bot/packets"

require 'socket'
require 'io/wait'
require 'thread'

module RedstoneBot
  class Client
    attr_reader :socket
    attr_reader :username
    attr_reader :hostname
    attr_reader :port

    def initialize(username, hostname, port)
      @username = username
      @hostname = hostname
      @port = port
      @listeners = []
    end
    
    def synchronize(&block)
      @mutex.synchronize(&block)
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
    
    def start
      @mutex = Mutex.new    
      @socket = TCPSocket.open hostname, port
      @socket.extend DataReader, DataEncoder
      
      send_packet Packet::Handshake.new(username, hostname, port)
      receive_packet
      
      send_packet Packet::LoginRequest.new(username)
      @eid = receive_packet.eid
      
      notify_listeners :start
      Thread.new do
        while true
          packet = Packet.receive(socket)
          notify_listeners packet
        end
      end
    end
    
    def send_packet(packet)
      packet.write(@socket)
    end
  end
end