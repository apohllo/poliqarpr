# vim:encoding=utf-8
module Poliqarp
  # Author:: Aleksander Pohl (mailto:apohllo@o2.pl)
  # License:: MIT License
  #
  # This class is the implementation of the Poliqarp server client.
  class Client
    # If debug is turned on, the communication between server and client
    # is logged to logger.
    attr_writer :debug

    # Logger used for debugging. STDOUT by default.
    attr_accessor :logger

    # The configuration of the client.
    attr_reader :config

    # Creates new poliqarp server client.
    #
    # Parameters:
    # * +session_name+ the name of the client session. Defaults to "RUBY".
    # * +debug+ if set to true, all messages sent and received from server
    #   are printed to standard output. Defaults to false.
    def initialize(session_name="RUBY", debug=false)
      @session_name = session_name
      @debug = debug
      @logger = STDOUT
      @connector = Connector.new(self)
      @config = Config.new(self,500000)
      @answer_queue = Queue.new
      @waiting_mutext = Mutex.new
      new_session
      config.left_context_size = 5
      config.right_context_size = 5
      config.tags = []
      config.lemmata = []
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
      talk("BUFFER-RESIZE #{config.buffer_size}")
      @session = true
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

    # Prints the debug +msg+ to the logger if debugging is turned on.
    # Accepts both regular message and block with message. The second
    # form is provided for messages which aren't cheep to build.
    def debug(msg=nil)
      if @debug
        if block_given?
          msg = yield
        end
        logger.puts msg
        logger.flush
      end
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
        talk("OPEN #{path}", :async, &handler)
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
    # Set the size of the left context.
    def left_context=(value)
      result = talk("SET left-context-width #{value}")
      unless result =~ /^OK/
        raise "Failed to set left context to #{value}: #{result}"
      end
    end

    # Set the size of the right context.
    def right_context=(value)
      result = talk("SET right-context-width #{value}")
      unless result =~ /^OK/
        raise "Failed to set right context to #{value}: #{result}"
      end
    end

    # Sets the 'retrieve-tags' flags.
    def retrieve_tags(flags)
      talk("SET retrieve-tags #{flags}")
    end

    # Sets the 'retrieve-lemmata' flags.
    def retrieve_lemmata(flags)
      talk("SET retrieve-lemmata #{flags}")
    end


    # Sends a message directly to the server
    # * +msg+ the message to send
    # * +mode+ if set to :sync, the method block untli the message
    #   is received. If :async the method returns immediately.
    #   Default: :sync
    # * +handler+ the handler of the assynchronous message.
    #   It is ignored when the mode is set to :sync.
    def talk(msg, mode = :sync, &handler)
      if mode == :sync
        @connector.send_message(msg, mode, &handler)
      else
        if handler.nil?
          real_handler = lambda do |msg|
            @answer_queue.push msg
            stop_waiting
          end
          start_waiting
        else
          real_handler = handler
        end
        @connector.send_message(msg, mode, &real_handler)
        if handler.nil?
          do_wait
        end
      end
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
        if config.lemmata.include?(group) || config.tags.include?(group)
          lemmata_size = read_number()
          lemmata_size.times do |lemmata_index|
            lemmata = Lemmata.new()
            if config.lemmata.include?(group)
              lemmata.base_form = read_word
            end
            if config.tags.include?(group)
              lemmata.tags = read_word
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

    # Reads string stored in the last message received from server
    def read_word
      @connector.read_message
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
        begin
          talk("MAKE-QUERY #{query}")
        rescue JobInProgress
          talk("CANCEL") rescue nil
          talk("MAKE-QUERY #{query}")
        end
        result = talk("RUN-QUERY #{config.buffer_size}", :async, &handler)
        if handler.nil?
          @last_result = result
        end
      else
        stop_waiting
      end
      @last_result
    end

    private
    # Wait for the assynchronous answer, if some synchronous query
    # was sent without handler.
    def do_wait
      loop {
        break unless should_wait?
        debug("WAITING")
        sleep 0.1
      }
      @answer_queue.shift
    end

    # Stop waiting for the ansynchonous answer.
    def stop_waiting
      @waiting_mutext.synchronize {
        @should_wait = false
      }
      debug("WAITING stopped")
    end

    # Check if the thread should still wait for the answer.
    def should_wait?
      should_wait = nil
      @waiting_mutext.synchronize {
        should_wait = @should_wait
      }
      should_wait
    end

    # Start waiting for the answer.
    def start_waiting
      @waiting_mutext.synchronize {
        @should_wait = true
      }
      debug("WAITING started")
    end

    def make_async_query(query,answer_offset)
      raise IndexOutOfBounds.new(answer_offset) if answer_offset > config.buffer_size
      start_waiting
      # we access the result count through BUFFER-STATE call
      make_query(query){|msg| stop_waiting}
      result_count = 0
      begin
        # the result count might be not exact!
        result_count = talk("BUFFER-STATE").split(" ")[2].to_i
        break unless should_wait?
      end while result_count < answer_offset
      @last_result = "OK #{result_count}"
      result_count
    end
  end
end
