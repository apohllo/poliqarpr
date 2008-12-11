module Poliqarp
  class Excerpt
    attr_reader :index, :base_form

    def initialize(index, client, base_form)
      @index = index
      @client = client
      @base_form = base_form
      @short_context = []
    end

    def <<(value)
      @short_context << value
    end


    def word
      #@short_context[0].split(/\s+/)[-1]
      @short_context[1].to_s
    end

    alias inflected_form word

    def to_s
      @short_context.join("")
    end

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
