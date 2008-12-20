module Poliqarp 
  class Segment
    attr_reader :literal, :lemmata

    def initialize(literal)
      @literal = literal
      @lemmata = []
    end

    def to_s 
      @literal
    end
  end
end
