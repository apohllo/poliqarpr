module Poliqarp
  # Author:: Aleksander Pohl (mailto:apohllo@o2.pl)
  # License:: MIT License
  #
  # The query result class is used to paginate results of the
  # query. Each query result has information about its context
  # (the next and previous page).
  class QueryResult
    include Enumerable

    attr_accessor :page, :page_count, :query, :page_size

    def initialize(page, page_count, page_size, client, query)
      @page = page
      @page_count = page_count
      @page_size = page_size
      @client = client
      @query = query
      @excerpts = []
    end

    # Adds excerpt to the query result
    def <<(excerpt)
      @excerpts << excerpt
    end

    # Allows to iterate over the results stored in the result
    def each
      @excerpts.each{|e| yield e}
    end

    [:first, :last, :empty?].each do |method|
      define_method method do
        @excerpts.send(method)
      end
    end

    # Returns excerpt with given index.
    def [](index)
      @excerpts[index]
    end

    # Two excerpts are equal iff their page number, page count,
    # query and page size are equal.
    def ==(other)
      return false unless other.is_a? QueryResult
      @page == other.page && @page_count == other.page_count &&
        @query == other.query && @page_size == other.page_size
    end

    # Returns the previous page of the query result
    def previous_page
      if @page > 1
        @client.find(@query, :page_size => @page_size,
                     :page_index => @page - 1)
      end
    end

    # Return the next page of the query result
    def next_page
      if @page < @page_count
        @client.find(@query, :page_size => @page_size,
                     :page_index => @page + 1)
      end
    end

    # Returns the number of excerpts stored in this page (query result)
    def size
      @excerpts.size
    end

    # Converts current query result page into an array.
    def to_a
      @excerpts.dup
    end

  end
end
