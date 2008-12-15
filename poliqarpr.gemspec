require 'rake'

Gem::Specification.new do |s|
  s.name = "poliqarpr"
  s.version = "0.0.2"
  s.date = "2008-12-15"
  s.summary = "Ruby client for Poliqarp"
  s.email = "apohllo@o2.pl"
  s.homepage = "http://www.apohllo.pl/projekty/poliqarpr"
  s.description = "Ruby client for Poliqarp (NLP corpus server)"
  s.has_rdoc = false
  s.authors = ['Aleksander Pohl']
  s.files = FileList["Rakefile", "poliqarpr.gemspec", 'lib/poliqarpr.rb',
    "changelog.txt", "lib/poliqarpr/*.rb", "corpus/*", "README.txt" ].to_a  
  s.test_files = FileList["spec/*.rb"].to_a
  s.rdoc_options = ["--main", "README.txt"]
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.txt"]
end

