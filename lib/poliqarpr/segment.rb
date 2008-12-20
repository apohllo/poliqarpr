module Poliqarp 
  # Author:: Aleksander Pohl (mailto:apohllo@o2.pl)
  # License:: MIT LICENSE
  #
  # The segment is the smallest meaningful part of the text.  
  # It may contain many lemmata, since the segments are sometimes 
  # not disambiguated. 
  class Segment
    attr_reader :literal, :lemmata

    # Creates new segment. The specified argument is the literal 
    # (as found in the text) representation of the segment. 
    def initialize(literal)
      @literal = literal
      @lemmata = []
    end

    # Returns the segment literal
    def to_s 
      @literal
    end
  end
end
