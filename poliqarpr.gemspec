Gem::Specification.new do |s|
  s.name = "poliqarpr"
  s.version = "0.0.5"
  s.date = "2009-12-10"
  s.summary = "Ruby client for Poliqarp"
  s.email = "apohllo@o2.pl"
  s.homepage = "http://www.github.com/apohllo/poliqarpr"
  s.description = "Ruby client for Poliqarp (NLP corpus server)"
  s.authors = ['Aleksander Pohl']
  s.files = ["Rakefile", "poliqarpr.gemspec", 
    "changelog.txt", "README.txt" ] + Dir.glob("lib/**/*")
  s.test_files = Dir.glob("test/**/*")
  s.rdoc_options = ["--main", "README.txt"]
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.txt"]
end

