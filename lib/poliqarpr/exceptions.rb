module Poliqarp
  # Author:: Aleksander Pohl (mailto:apohllo@o2.pl)
  # License:: MIT License

  # The JobInProgress exception is raised if there was asynchronous call
  # to the server which haven't finished, which is interrupted by another
  # asynchronous call.
  class JobInProgress < Exception; end

  # The IndexOutOfBounds exception is raised if the index of given excerpt
  # is larger than the size of query buffer.
  class IndexOutOfBounds < Exception
    def initialize(index)
      super
      @index = index
    end

    def to_s
      "Poliqarp::IndexOutOfBounds(#{@index})"
    end
  end
end
