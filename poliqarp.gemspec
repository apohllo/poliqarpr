Gem::Specification.new do |s|
  s.name = "poliqarp"
  s.version = "0.0.2"
  s.date = "2008-11-23"
  s.summary = "Ruby client for Poliqarp"
  s.email = "apohllo@o2.pl"
  s.homepage = "http://www.korpus.pl"
  s.description = "Ruby client for Poliqarp (NLP corpus server)"
  s.has_rdoc = false
  s.authors = ['Aleksander Pohl']
  s.files = ["Rakefile", "poliqarp.gemspec", 'lib/poliqarp.rb',
    "changelog.txt", "lib/poliqarp/client.rb", "lib/poliqarp/excerpt.rb",
    "lib/poliqarp/query_result.rb" ]  
  s.test_files = []
  #s.rdoc_options = ["--main", "README.txt"]
  #s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  #s.add_dependency("RubyInline", [">= 3.7.0"])
  #s.add_dependency("unicode", [">= 0.0.1"])
end

