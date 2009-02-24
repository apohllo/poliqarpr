begin
  require 'poliqarpr-corpus' 
rescue LoadError
  # Do nothig, since the default corpus is optional
end

$LOAD_PATH.unshift File.dirname(__FILE__)
Dir.glob(File.join(File.dirname(__FILE__), 'poliqarpr/**.rb')).each { |f| require f }

