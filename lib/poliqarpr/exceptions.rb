module Poliqarp
  # Author:: Aleksander Pohl (mailto:apohllo@o2.pl)
  # License:: MIT License

  # The JobInProgress exception is raised if there was asynchronous call 
  # to the server which haven't finished, which is interrupted by another
  # asynchronous call.
  class JobInProgress < Exception; end
end
