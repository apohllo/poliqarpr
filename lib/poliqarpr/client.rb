module Poliqarp
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
    attr_writer :debug

    def initialize(session_name="RUBY", debug=false)
      @session_name = session_name
      @left_context = 5
      @right_context = 5
      @debug = debug
      @buffer_size = 500000
      new_session
    end

    def new_session
      close if @session
      @socket = TCPSocket.new("localhost",4567)
      talk "MAKE-SESSION #{@session_name}"
      rcv_sync
      talk("BUFFER-RESIZE #{@buffer_size}")
      rcv_sync
      @session = true
      self.tags = {}
      self.lemmata = {}
    end

    def talk(msg)
      puts msg if @debug
      @socket.puts(msg)
    end

    def close
      #talk "CLOSE"
      #rcv_sync
      talk "CLOSE-SESSION" 
      rcv_sync
      #@socket.close
      @session = false
    end

    def left_context=(value)
      if value.is_a? Fixnum
        talk "SET left-context-width #{value}" 
        result = rcv_sync 
        @left_context = value if result =~ /^R OK/
      end
    end

    def right_context=(value)
      if value.is_a? Fixnum
        talk "SET right-context-width #{value}"     
        result = rcv_sync 
        @right_context = value if result =~ /^R OK/
      end
    end

    def tags=(options={})
      flags = ""
      [:left_context_tags, :leftM_tags, 
        :rightM_tags, :right_context_tags].each do |flag|
        flags << (options[flag] ? "1" : "0")
        end
      talk "SET retrieve-tags #{flags}"
      rcv_sync
    end

    def lemmata=(options={})
      flags = ""
      [:left_context_lemmata, :leftM_lemmata, 
        :rightM_lemmata, :right_context_lemmata].each do |flag|
        flags << (options[flag] ? "1" : "0")
        end
      talk "SET retrieve-lemmata #{flags}"
      rcv_sync
    end


    def open_corpus(path)
      if path == :default
        open_corpus(DEFAULT_CORPUS)
      else
        talk("OPEN #{path}")
        rcv_sync
        rcv_async
      end
    end

    def find(query,options={})
      if options[:index]
        find_one(query, options[:index])
      else
        find_many(query, options)
      end
    end

    alias query find 

    def count(query)
      count_results(make_query(query)) 
    end

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
    #
    # MAKE-QUERY and GET-RESULTS must be called on server before 
    # this method is called
    def fetch_result(index, query)
      result = Excerpt.new(index, self, query)
      # left_context
      result << read_segments
      # matched query
      result << read_segments
      # right context
      result << read_segments

      result
    end

    def read_segments
      answer = rcv_sync
      size = answer.match(/\d+/)[0].to_i
      segments = []
      size.times do |segment_index|
        segments << read_word
      end
      segments.join("")
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
  end 
end
