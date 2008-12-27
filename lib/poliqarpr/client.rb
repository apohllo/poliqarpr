module Poliqarp
  # Author:: Aleksander Pohl (mailto:apohllo@o2.pl)
  # License:: MIT License
  #
  # This class is the implementation of the Poliqarp server client. 
  class Client
    GROUPS = [:left_context, :left_match, :right_match, :right_context]

    # If debug is turned on, the communication between server and client 
    # is logged to standard output.
    attr_writer :debug

    # The size of the buffer is the maximum number of excerpts which
    # are returned for single query.
    attr_writer :buffer_size

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
      @connector = Connector.new(debug)
      @answer_queue = Queue.new
      new_session
    end

    # A hint about installation of default corpus gem
    def self.const_missing(const)
      if const.to_s =~ /DEFAULT_CORPUS/ 
        raise "You need to install 'apohllo-poliqarpr-corpus' to use the default corpus"
      end
      super
    end

    # Creates new session for the client with the name given in constructor. 
    # If the session was already opened, it is closed. 
    #
    # Parameters: 
    # * +port+ - the port on which the poliqarpd server is accepting connections (defaults to 4567)
    def new_session(port=4567)
      close if @session
      @connector.open("localhost",port)
      talk("MAKE-SESSION #{@session_name}")
      talk("BUFFER-RESIZE #{@buffer_size}")
      @session = true
      self.tags = {}
      self.lemmata = {}
    end

    # Closes the opened session.
    def close
      talk "CLOSE-SESSION" 
      @session = false
    end

    # Closes the opened corpus.
    def close_corpus
      talk "CLOSE"
    end

    # Sets the size of the left short context. It must be > 0
    #
    # The size of the left short context is the number 
    # of segments displayed in the found excerpts left to the
    # matched segment(s).
    def left_context=(value)
      if correct_context_value?(value) 
        result = talk("SET left-context-width #{value}")
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
      if correct_context_value?(value)
        result = talk("SET right-context-width #{value}")
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
      talk("SET retrieve-tags #{flags}")
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
      talk("SET retrieve-lemmata #{flags}")
    end

    # *Asynchronous* Opens the corpus given as +path+. To open the default
    # corpus pass +:default+ as the argument. 
    # 
    # If you don't want to wait until the call is finished, you
    # have to provide +handler+ for the asynchronous answer.
    def open_corpus(path, &handler)
      if path == :default
        open_corpus(DEFAULT_CORPUS, &handler)
      else
        real_handler = handler || lambda{|msg| @answer_queue.push msg }
        talk("OPEN #{path}", :async, &real_handler)
        do_wait if handler.nil?
      end
    end

    # Server diagnostics -- the result should be :pong
    def ping 
      :pong if talk("PING") =~ /PONG/
    end

    # Returns server version
    def version 
      talk("VERSION")
    end

    # Returns corpus statistics:
    # * +:segment_tokens+ the number of segments in the corpus 
    #   (two segments which look exactly the same are counted separately)
    # * +:segment_types+ the number of segment types in the corpus
    #   (two segments which look exactly the same are counted as one type)
    # * +:lemmata+ the number of lemmata (lexemes) types
    #   (all forms of inflected word, e.g. 'kot', 'kotu', ... 
    #   are treated as one "word" -- lemmata)
    # * +:tags+ the number of different grammar tags (each combination
    #   of atomic tags is treated as different "tag")
    def stats
      stats = {}
      talk("CORPUS-STATS").split.each_with_index do |value, index|
        case index
        when 1 
          stats[:segment_tokens] = value.to_i
        when 2
          stats[:segment_types] = value.to_i
        when 3
          stats[:lemmata] = value.to_i
        when 4
          stats[:tags] = value.to_i
        end
      end
      stats
    end

    # TODO
    def metadata_types
      raise "Not implemented"
    end

    # Returns the tag-set used in the corpus.
    # It is divided into two groups:
    # * +:categories+ enlists tags belonging to grammatical categories
    #   (each category has a list of its tags, eg. gender: m1 m2 m3 f n,
    #   means that there are 5 genders: masculine(1,2,3), feminine and neuter)
    # * +:classes+ enlists grammatical tags used to describe it
    #   (each class has a list of tags used to describe it, eg. adj: degree 
    #   gender case number, means that adjectives are described in terms
    #   of degree, gender, case and number)
    def tagset
      answer = talk("GET-TAGSET")
      counters = answer.split
      result = {}
      [:categories, :classes].each_with_index do |type, type_index|
        result[type] = {}
        counters[type_index+1].to_i.times do |index|
          values = read_word.split
          result[type][values[0].to_sym] = values[1..-1].map{|v| v.to_sym}
        end
      end
      result
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
      answer = talk("METADATA #{index}")
      count = answer.split(" ")[1].to_i
      count.times do |index|
        type = read_word.gsub(/[^a-zA-Z]/,"").to_sym
        value = read_word[2..-1]
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
    # * +mode+ if set to :sync, the method block untli the message
    #   is received. If :async the method returns immediately.
    #   Default: :sync
    # * +handler+ the handler of the assynchronous message. 
    #   It is ignored when the mode is set to :sync.
    def talk(msg, mode = :sync, &handler)
      puts msg if @debug
      @connector.send(msg, mode, &handler)
    end

    # Make query and retrieve many results. 
    # * +query+ the query to be sent to the server.
    # * +options+ see find
    def find_many(query, options)
      page_size = (options[:page_size] || 0)
      page_index = (options[:page_index] || 1)

      answer_offset = page_size * (page_index - 1)
      if page_size > 0
        result_count = make_async_query(query,answer_offset)
        answers_limit = answer_offset + page_size > result_count ?  
          result_count - answer_offset : page_size
      else
        # all answers needed -- the call must be synchronous
        result_count = count_results(make_query(query))
        answers_limit = result_count
      end

      page_count = page_size <= 0 ? 1 :
        result_count / page_size + (result_count % page_size > 0 ? 1 : 0)

      result = QueryResult.new(page_index, page_count,page_size,self,query)
      if answers_limit > 0
        talk("GET-RESULTS #{answer_offset} #{answer_offset + answers_limit - 1}") 
        answers_limit.times do |answer_index|
          result << fetch_result(answer_offset + answer_index, query)
        end
      end
      result 
    end

    # Make query and retrieve only one result
    # * +query+ the query to be sent to the server
    # * +index+ the index of the answer to be retrieved
    def find_one(query,index)
      make_async_query(query,index)
      talk("GET-RESULTS #{index} #{index}") 
      fetch_result(index,query) 
    end

    # Fetches one result of the query
    #
    # MAKE-QUERY and GET-RESULTS must be sent to the server before 
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
      size = read_number()
      segments = []
      size.times do |segment_index|
        segment = Segment.new(read_word)
        segments << segment 
        if @lemmata_flags[group] || @tag_flags[group]
          lemmata_size = read_number()
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

    # Reads number stored in the message received from the server.
    def read_number
      @connector.read_message.match(/\d+/)[0].to_i
    end

    # Counts number of results for given answer
    def count_results(answer)
      answer.split(" ")[1].to_i
    end

    # *Asynchronous* Sends the query to the server
    # * +query+ query to send
    # * +handler+ if given, the method returns immediately, 
    #   and the answer is sent to the handler. In this case
    #   the result returned by make_query should be IGNORED!
    def make_query(query, &handler)
      if @last_query != query
        @last_query = query
        if handler.nil?
          real_handler = lambda { |msg| @answer_queue.push msg }
        else
          real_handler = handler
        end
        begin
          talk("MAKE-QUERY #{query}")
        rescue JobInProgress
          talk("CANCEL") rescue nil
          talk("MAKE-QUERY #{query}")
        end
        talk("RUN-QUERY #{@buffer_size}", :async, &real_handler) 
        @last_result = do_wait if handler.nil?
      end
      @last_result
    end

    # Reads string stored in the last message received from server
    def read_word
      @connector.read_message
    end

private 
    def do_wait
      loop {
        status = talk("STATUS") rescue break
        puts "STATUS: #{status}" if @debug
        sleep 0.3
      }
      @answer_queue.shift
    end

    def set_all_flags
      options = {}
      GROUPS.each{|g| options[g] = true}
      options
    end
    
    def correct_context_value?(value)
      value.is_a?(Fixnum) && value > 0
    end

    def make_async_query(query,answer_offset) 
      # the handler is empty, since we access the result count through 
      # BUFFER-STATE call
      make_query(query){|msg| }
      result_count = 0 
      begin 
        # the result count might be not exact!
        result_count = talk("BUFFER-STATE").split(" ")[2].to_i
        talk("STATUS") rescue break
      end while result_count < answer_offset
      @last_result = "OK #{result_count}"
      result_count
    end
  end 
end
