require 'socket'
module Poliqarp
  # Author:: Aleksander Pohl (mailto:apohllo@o2.pl)
  # License:: MIT License
  #
  # This class is the implementation of the Poliqarp server client. 
  class Client
    DEFAULT_CORPUS = File.join(File.expand_path(File.dirname(__FILE__)),"..", "..", "corpus", "frek")
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
    GROUPS = [:left_context, :left_match, :right_match, :right_context]
    attr_writer :debug


    # Creates new poliqarp server client. 
    # 
    # Parameters:
    # * +session_name+ the name of the client session. Defaults to "RUBY".
    # * +debug+ if set to true, all messages sent and received from server
    #   are printed to standard output. Defaults to false.
    def initialize(session_name="RUBY", debug=false)
      @session_name = session_name
      @left_context = 5
      @right_context = 5
      @debug = debug
      @buffer_size = 500000
      new_session
    end

    # Creates new session for the client with the name given in constructor. 
    # If the session was already opened, it is closed. 
    #
    # Parameters: 
    # * +port+ - the port on which the poliqarpd server is accepting connections (defaults to 4567)
    def new_session(port=4567)
      close if @session
      @socket = TCPSocket.new("localhost",port)
      talk "MAKE-SESSION #{@session_name}"
      rcv_sync
      talk("BUFFER-RESIZE #{@buffer_size}")
      rcv_sync
      @session = true
      self.tags = {}
      self.lemmata = {}
    end

    # Closes the opened connection to the poliqarpd server.
    def close
      #talk "CLOSE"
      #rcv_sync
      talk "CLOSE-SESSION" 
      rcv_sync
      #@socket.close
      @session = false
    end

    # Sets the size of the left short context. It must be > 0
    #
    # The size of the left short context is the number 
    # of segments displayed in the found excerpts left to the
    # matched segment(s).
    def left_context=(value)
      if value.is_a? Fixnum && value > 0
        talk "SET left-context-width #{value}" 
        result = rcv_sync 
        @left_context = value if result =~ /^R OK/
      else
        raise "Invalid argument: #{value}. It must be fixnum greater than 0."
      end
    end

    # Sets the size of the right short context. It must be > 0
    #
    # The size of the right short context is the number 
    # of segments displayed in the found excerpts right to the
    # matched segment(s).
    def right_context=(value)
      if value.is_a? Fixnum && value > 0
        talk "SET right-context-width #{value}"     
        result = rcv_sync 
        @right_context = value if result =~ /^R OK/
      else
        raise "Invalid argument: #{value}. It must be fixnum greater than 0."
      end
    end

    # Sets the tags' flags. There are four groups of segments 
    # which the flags apply for:
    # * +left_context+
    # * +left_match+
    # * +right_match+
    # * +right_context+
    #
    # If the flag for given group is set to true, all segments 
    # in the group are annotated with grammatical tags. E.g.:
    #  c.find("kot")
    #  ...
    #  "kot" tags: "subst:sg:nom:m2"
    #
    # You can pass :all to turn on flags for all groups
    def tags=(options={})
      options = set_all_flags if options == :all
      @tag_flags = options
      flags = ""
      GROUPS.each do |flag|
        flags << (options[flag] ? "1" : "0")
        end
      talk "SET retrieve-tags #{flags}"
      rcv_sync
    end

    # Sets the lemmatas' flags. There are four groups of segments 
    # which the flags apply for:
    # * +left_context+
    # * +left_match+
    # * +right_match+
    # * +right_context+
    #
    # If the flag for given group is set to true, all segments 
    # in the group are returned with the base form of the lemmata. E.g.:
    #  c.find("kotu")
    #  ...
    #  "kotu" base_form: "kot"
    #
    # You can pass :all to turn on flags for all groups
    def lemmata=(options={})
      options = set_all_flags if options == :all
      @lemmata_flags = options
      flags = ""
      GROUPS.each do |flag|
        flags << (options[flag] ? "1" : "0")
        end
      talk "SET retrieve-lemmata #{flags}"
      rcv_sync
    end

    # Opens the corpus given as +path+. To open the default
    # corpus pass +:default+ as the argument. 
    def open_corpus(path)
      if path == :default
        open_corpus(DEFAULT_CORPUS)
      else
        talk("OPEN #{path}")
        rcv_sync
        rcv_async
      end
    end

    # Send the query to the opened corpus.
    #
    # Options:
    # * +index+ the index of the (only one) result to be returned. The index is relative
    #   to the beginning of the query result. In normal case you should query the 
    #   corpus without specifying the index, to see what results are returned.
    #   Then you can use the index and the same query to retrieve one result. 
    #   The pair (query, index) is a kind of unique identifier of the excerpt.
    # * +page_size+ the size of the page of results. If the page size is 0, then
    #   all results are returned on one page. It is ignored if the +index+ option
    #   is present. Defaults to 0.
    # * +page_index+ the index of the page of results (the first page has index 1, not 0). 
    #   It is ignored if the +index+ option is present. Defaults to 1.
    def find(query,options={})
      if options[:index]
        find_one(query, options[:index])
      else
        find_many(query, options)
      end
    end

    alias query find 

    # Returns the number of results for given query.
    def count(query)
      count_results(make_query(query)) 
    end

    # Returns the long context of the excerpt which is identified by
    # given (query, index) pair.
    def context(query,index)
      make_query(query)
      result = []
      talk "GET-CONTEXT #{index}"
      # R OK
      rcv_sync
      # 1st part
      result << read_word 
      # 2nd part
      result << read_word 
      # 3rd part
      result << read_word 
      # 4th part
      result << read_word 
      result
    end

    # Returns the metadata of the excerpt which is identified by
    # given (query, index) pair.
    def metadata(query, index)
      make_query(query)
      result = {}
      talk "METADATA #{index}"
      count = rcv_sync.split(" ")[2].to_i
      count.times do |index|
        type = read_word.gsub(/[^a-zA-Z]/,"").to_sym
        value = rcv_sync[4..-2]
        unless value.nil?
          result[type] ||= []
          result[type] << value
        end
      end
      result
    end

protected
    # Sends a message directly to the server
    # * +msg+ the message to send
    def talk(msg)
      puts msg if @debug
      @socket.puts(msg)
    end

    def find_many(query, options)
      page_size = (options[:page_size] || 0)
      page_index = (options[:page_index] || 1)
      answers = make_query(query)
      #talk("GET-COLUMN-TYPES")
      #rcv_sync
      result_count = count_results(answers)
      answer_offset = page_size * (page_index - 1)
      if page_size > 0
        answers_limit = answer_offset + page_size > result_count ?  
          result_count - answer_offset : page_size
      else
        answers_limit = result_count
      end
      page_count = if page_size > 0
                     result_count / page_size + (result_count % page_size > 0 ? 1 : 0)
                   else
                     1
                   end
      result = QueryResult.new(page_index, page_count,page_size,self,query)
      if answers_limit > 0
        talk("GET-RESULTS #{answer_offset} #{answer_offset + answers_limit - 1}") 
        # R OK              1
        rcv_sync

        answers_limit.times do |answer_index|
          result << fetch_result(answer_offset + answer_index, query)
        end
      end
      result 
    end

    def find_one(query,index)
      make_query(query)
      talk("GET-RESULTS #{index} #{index}") 
      # R OK              1
      rcv_sync
      fetch_result(index,query) 
    end

    # Fetches one result of the query
    ##
    # MAKE-QUERY and GET-RESULTS must be called on server before 
    # this method is called
    def fetch_result(index, query)
      result = Excerpt.new(index, self, query)
      result << read_segments(:left_context)
      result << read_segments(:left_match)
      # XXX
      #result << read_segments(:right_match)
      result << read_segments(:right_context)

      result
    end

    def read_segments(group)
      size = get_number(rcv_sync)
      segments = []
      size.times do |segment_index|
        segment = Segment.new(read_word)
        segments << segment 
        if @lemmata_flags[group] || @tag_flags[group]
          lemmata_size = get_number(rcv_sync)
          lemmata_size.times do |lemmata_index| 
            lemmata = Lemmata.new()
            if @lemmata_flags[group]
              lemmata.base_form = read_word
            end
            if @tag_flags[group]
              read_word
            end
            segment.lemmata << lemmata
          end
        end
      end
      segments
    end

    def get_number(str)
      str.match(/\d+/)[0].to_i
    end

    def count_results(answer)
      answer.split(" ")[2].to_i
    end

    def make_query(query)
      if @last_query != query
        @last_query = query
        talk("MAKE-QUERY #{query}")
        rcv_sync
        talk("RUN-QUERY #{@buffer_size}")
        @last_query_result = rcv_async
      end
      @last_query_result 
    end

    def read_word
      rcv_sync[2..-2]
    end

    def read_line
      line = ""
      begin
        chars = @socket.recvfrom(1)
        line << chars[0]
      end while chars[0] != "\n"
      line
    end

    def error_message(line)
      RuntimeError.new("Poliqarp Error: "+ERRORS[line.match(/\d+/)[0].to_i])
    end

    # XXX
    def rcv_sync
      result = read_line
      puts result if @debug
      raise error_message(result) if result =~ /^R ERR/
      result
      #    @socket.recvfrom(1024)
    end

    # XXX
    def rcv_async
      begin
        line = read_line
        raise error_message(line) if line =~ /^. ERR/
        puts line if @debug
      end until line =~ /^M/
      line
    end

private 
    def set_all_flags
      options = {}
      GROUPS.each{|g| options[g] = true}
      options
    end
  end 
end
