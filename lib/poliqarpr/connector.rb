# vim:encoding=utf-8
require 'socket'
require 'thread'
require File.join(File.dirname(__FILE__),'util')

module Poliqarp
  # Author:: Aleksander Pohl (mailto:apohllo@o2.pl)
  # License:: MIT License
  #
  # This class hold the TCP connection to the server and is responsible
  # for dispatching synchronous and asynchronous queries and answers.
  class Connector
    include Ruby19

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

    UTF8 = "utf-8"

    # Creates new connector
    def initialize(client)
      @message_queue = Queue.new
      @socket_mutex = Mutex.new
      @loop_mutex = Mutex.new
      @client = client
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
    def send_message(message, mode, &handler)
      @client.debug{"send #{mode} #{message}"}
      if ruby19?
        massage = message.encode(UTF8)
      end
      @socket.write(message+"\n")
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
        code = message.match(/\d+/)[0].to_i
        case code
        when 15
          raise JobInProgress.new()
        else
          raise RuntimeError.new("Poliqarp Error: "+ERRORS[code])
        end
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
      if ruby19?
        result.force_encoding(UTF8)
      end
      msg = result[2..-2]
      if result =~ /^M/
        receive_async(msg)
      elsif result
        receive_sync(msg)
      end
      # if nil, nothing was received
    end

    def receive_sync(message)
      @client.debug{"receive sync: #{message}"}
      @message_queue << message
    end

    def receive_async(message)
      @client.debug{"receive async: #{message}"}
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
