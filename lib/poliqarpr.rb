path = File.join(File.dirname(__FILE__), 'poliqarpr')
require File.join(path, 'client')
require File.join(path, 'query_result')
require File.join(path, 'excerpt')
require File.join(path, 'segment')
require File.join(path, 'lemmata')
require File.join(path, 'connector')
begin
  require 'poliqarpr-corpus' 
rescue LoadError
  # Do nothig, since the default corpus is optional
end
