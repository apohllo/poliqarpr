#vim:encoding=utf-8
module Poliqarp #:nodoc:
  module Ruby19
    # Returns true if the Ruby version is at least 1.9.0
    def ruby19?
      RUBY_VERSION.split(".")[0..1].join(".").to_f >= 1.9
    end
  end
end
