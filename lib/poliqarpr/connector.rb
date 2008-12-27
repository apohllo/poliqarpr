require 'socket'

module Poliqarp
  class Connector

    # Error messages assigned to error codes
    # (taken from poliqarpd implementation)
    ERRORS = {
      1 =>   "Incorrect number of arguments",
      3 =>   "No session opened",
      4 =>   "Cannot create a session for a connection that",
      5 =>   "Not enough memory",
      6 =>   "Invalid session ID",
      7 =>   "Session with this ID is already bound",
      8 =>   "Session user ID does not match the argument",
      10 =>   "Session already has an open corpus",
      12 =>   "System error while opening the corpus",
      13 =>   "No corpus opened",
      14 =>   "Invalid job ID",
      15 =>   "A job is already in progress",
      16 =>   "Incorrect query",
      17 =>   "Invalid result range",
      18 =>   "Incorrect session option",
      19 =>   "Invalid session option value",
      20 =>   "Invalid sorting criteria"
    }

    # Creates new connector
    def initialize(debug)
      @message_queue = Queue.new
      @socket_mutex = Mutex.new
      @loop_mutex = Mutex.new
      @debug = debug
    end

    # Opens connection with poliqarp server which runs 
    # on given +host+ and +port+.
    def open(host,port)
      @socket_mutex.synchronize {
        @socket = TCPSocket.new(host,port) if @socket.nil?
      }
      running = nil
      @loop_mutex.synchronize {
        running = @loop_running
      }
      main_loop unless running
      @loop_mutex.synchronize {
        @loop_running = true
      }
    end

    # Sends message to the poliqarp server. Returns the first synchronous 
    # answer of the server.
    # * +message+ the message to send
    # * +mode+ synchronous (+:sync:) or asynchronous (+:async+)
    # * +handler+ the handler of the asynchronous message
    def send(message, mode, &handler)
      puts "send #{mode} #{message}" if @debug
      @socket.puts(message)
      if mode == :async
        @handler = handler
      end
      read_message
    end

    # Retrives one message from the server.
    # If the message indicates an error, new runtime error 
    # containing the error description is returned.
    def read_message
      message = @message_queue.shift
      if message =~ /^ERR/
        raise RuntimeError.new("Poliqarp Error: "+ERRORS[message.match(/\d+/)[0].to_i])
      else
        message
      end
    end

private
    def main_loop
      @loop = Thread.new { 
        loop {
          receive
          # XXX ??? needed
          #sleep 0.001
        }
      }
    end

    def receive
      result = read_line
      msg = result[2..-2]
      if result =~ /^M/
        receive_async(msg)
      elsif result
        receive_sync(msg)
      end
      # if nil, nothing was received
    end

    def receive_sync(message)
      puts "receive sync: #{message}" if @debug
      @message_queue << message
    end

    def receive_async(message)
      puts "receive async: #{message}" if @debug
      Thread.new{ 
        @handler.call(message) 
      }
    end

    def read_line
      line = ""
      begin
        chars = @socket.recvfrom(1)
        line << chars[0]
      end while chars[0] != "\n"
      line
    end
  end
end
