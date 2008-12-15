module Poliqarp
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

    def <<(excerpt)
      @excerpts << excerpt
    end

    def each
      @excerpts.each{|e| yield e}
    end

    [:first, :last, :empty?].each do |method|
      define_method method do
        @excerpts.send(method)
      end
    end

    def [](index)
      @excerpts[index]
    end

    def ==(other)
      return false unless other.is_a? QueryResult
      @page == other.page && @page_count == other.page_count &&
        @query == other.query && @page_size == other.page_size
    end

    def previous_page
      if @page > 1
        @client.find(@query, :page_size => @page_size, 
                     :page_index => @page - 1) 
      end
    end

    def next_page
      if @page < @page_count
        @client.find(@query, :page_size => @page_size, 
                     :page_index => @page + 1) 
      end
    end

    def size
      @excerpts.size
    end

  end
end
