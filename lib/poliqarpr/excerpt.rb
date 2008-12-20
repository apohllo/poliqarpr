module Poliqarp
  # Author:: Aleksander Pohl
  # License:: MIT License
  #
  # The excerpt class is used to store single result of the query, 
  # i.e. the excerpt of the corpus which contains the words which
  # the corpus was queried for. 
  #
  # The excerpt is divided into groups, which contain segments,
  # which the texts in the corpus were divided for. 
  # The first group is the left context, the second -- the matched 
  # query, and the last -- the right context.
  class Excerpt
    attr_reader :index, :base_form, :short_context

    def initialize(index, client, base_form)
      @index = index
      @client = client
      @base_form = base_form
      @short_context = []
    end

    # Adds segment group to the excerpt
    def <<(value)
      @short_context << value
    end


    # Returns the matched query as string 
    def word
      #@short_context[0].split(/\s+/)[-1]
      @short_context[1].to_s
    end

    alias inflected_form word

    # The string representation of the excerpt is the shord
    # context of the query.
    def to_s
      @short_context.join("")
    end

    # Returns the long context of the query. 
    def context
      return @context unless @context.nil?
      @context = @client.context(@base_form, @index)
    end

    { :medium => :medium, :style => :styl, :date => :data_wydania,
      :city => :miejsce_wydania, :publisher => :wydawca, :title => :tytu,
      :author => :autor}.each do |method, keyword|
      define_method method do 
        self.metadata[keyword]
      end
      end

    protected
    def metadata
      return @metadata unless @metadata.nil?
      @metadata = @client.metadata(@base_form, @index)
    end
  end
end
