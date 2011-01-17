# vim:encoding=utf-8
module Poliqarp
  # Author:: Aleksander Pohl (mailto:apohllo@o2.pl)
  # License:: MIT License
  #
  # This class holds the configuration of the client.
  class Config
    GROUPS = [:left_context, :left_match, :right_match, :right_context]
    # The size of the buffer is the maximum number of excerpts which
    # are returned for single query.
    attr_accessor :buffer_size, :left_context_size, :right_context_size, :tags, :lemmata

    def initialize(client,buffer_size)
      @client = client
      @buffer_size = buffer_size
    end

    # Sets the size of the left short context. It must be > 0
    #
    # The size of the left short context is the number
    # of segments displayed in the found excerpts left to the
    # matched segment(s).
    def left_context_size=(value)
      if correct_context_value?(value)
        @client.send(:left_context=,value)
        @left_context_size = value
      else
        raise "Invalid argument: #{value}. It must be fixnum greater than 0."
      end
    end

    # Sets the size of the right short context. It must be > 0
    #
    # The size of the right short context is the number
    # of segments displayed in the found excerpts right to the
    # matched segment(s).
    def right_context_size=(value)
      if correct_context_value?(value)
        @client.send(:right_context=,value)
        @right_context_size = value
      else
        raise "Invalid argument: #{value}. It must be fixnum greater than 0."
      end
    end

    # Sets the tags' flags. There are four groups of segments
    # which the flags apply for:
    # * +:left_context+
    # * +:left_match+
    # * +:right_match+
    # * +:right_context+
    #
    # If the flag for given group is present, all segments
    # in the group are annotated with grammatical tags. E.g.:
    #  c.find("kot")
    #  ...
    #  "kot" tags: "subst:sg:nom:m2"
    #
    # E.g. config.tags = [:left_context] will retrieve tags
    # only for the left context.
    #
    # You can pass :all to turn on flags for all groups, i.e.
    # config.tags = :all will retrieve tags for all groups.
    def tags=(groups)
      if groups == :all
        @tags = GROUPS.dup
      else
        @tags = groups
      end
      @client.send(:retrieve_tags, flags_for(@tags))
    end

    # Sets the lemmatas' flags. There are four groups of segments
    # which the flags apply for:
    # * +left_context+
    # * +left_match+
    # * +right_match+
    # * +right_context+
    #
    # If the flag for given group is present, all segments
    # in the group are returned with the base form of the lemmata. E.g.:
    #  c.find("kotu")
    #  ...
    #  "kotu" base_form: "kot"
    #
    # E.g. config.lemmata = [:left_context] will retrieve lemmata
    # only for the left context.
    #
    # You can pass :all to turn on flags for all groups, i.e.
    # config.lemmata = :all will retrieve lemmata for all groups.
    def lemmata=(groups)
      if groups == :all
        @lemmata = GROUPS.dup
      else
        @lemmata = groups
      end
      @client.send(:retrieve_lemmata, flags_for(@lemmata))
    end

    # Allow for accessing individual group tags/lemmata flag,
    # e.g. config.left_context_tags, config.left_context_lemmata
    [:tags,:lemmata].each do |type|
      GROUPS.each do |group|
        define_method("#{group}_#{type}".to_sym) do
          @tags.include?(group)
        end
      end
    end

    # Allow for changing individual group tags/lemmata flag,
    # e.g. config.left_context_tags = true, config.left_context_lemmata = true
    [:tags,:lemmata].each do |type|
      GROUPS.each do |group|
        define_method("#{group}_#{type}=".to_sym) do |value|
          if value
            @tags << group unless @tags.include?(group)
          else
            @tags.delete(group) if @tags.include?(group)
          end
          @client.send("retrieve_#{type}".to_sym, flags_for(@tags))
        end
      end
    end

    protected
    def correct_context_value?(value)
      value.is_a?(Fixnum) && value > 0
    end

    def flags_for(elements)
      flags = ""
      GROUPS.each do |flag|
        flags << (elements.include?(flag) ? "1" : "0")
      end
      flags
    end
  end
end
