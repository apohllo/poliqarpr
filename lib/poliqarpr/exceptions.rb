module Poliqarp
  # Author:: Aleksander Pohl (mailto:apohllo@o2.pl)
  # License:: MIT License

  # Base for all poliqarp exceptions.
  class PoliqarpException < Exception; end

  # The JobInProgress exception is raised if there was asynchronous call
  # to the server which haven't finished, which is interrupted by another
  # asynchronous call.
  class JobInProgress < PoliqarpException; end

  # The InvalidJobId exceptions is raised when there is no job to be cancelled.
  class InvalidJobId < PoliqarpException; end

  # The IndexOutOfBounds exception is raised if the index of given excerpt
  # is larger than the size of query buffer.
  class IndexOutOfBounds < PoliqarpException
    def initialize(index)
      super
      @index = index
    end

    def to_s
      "Poliqarp::IndexOutOfBounds(#{@index})"
    end
  end
end
