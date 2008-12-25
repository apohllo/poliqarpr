Gem::Specification.new do |s|
  s.name = "poliqarpr"
  s.version = "0.0.3"
  s.date = "2008-12-20"
  s.summary = "Ruby client for Poliqarp"
  s.email = "apohllo@o2.pl"
  s.homepage = "http://www.apohllo.pl/projekty/poliqarpr"
  s.description = "Ruby client for Poliqarp (NLP corpus server)"
  s.authors = ['Aleksander Pohl']
  s.files = ["Rakefile", "poliqarpr.gemspec", 'lib/poliqarpr.rb',
    "changelog.txt", 
    "lib/poliqarpr/client.rb", 
    "lib/poliqarpr/query_result.rb", 
    "lib/poliqarpr/excerpt.rb", 
    "lib/poliqarpr/lemmata.rb", 
    "lib/poliqarpr/segment.rb", 
    "README.txt",
  ]
  s.test_files = [
    "spec/client.rb",
    "spec/query_result.rb",
    "spec/excerpt.rb"
  ]
  s.rdoc_options = ["--main", "README.txt"]
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.txt"]
end

