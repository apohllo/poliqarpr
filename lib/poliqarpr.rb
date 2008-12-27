require 'poliqarpr/client'
require 'poliqarpr/query_result'
require 'poliqarpr/excerpt'
require 'poliqarpr/segment'
require 'poliqarpr/lemmata'
require 'poliqarpr/connector'
require 'poliqarpr/exceptions'
begin
  require 'poliqarpr-corpus' 
rescue LoadError
  # Do nothig, since the default corpus is optional
end
