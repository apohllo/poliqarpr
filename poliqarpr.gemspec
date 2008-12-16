#require 'rake'

Gem::Specification.new do |s|
  s.name = "poliqarpr"
  s.version = "0.0.2"
  s.date = "2008-12-15"
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
    "README.txt",
    "corpus/frek.cdf",
    "corpus/frek.poliqarp.base1.image",
    "corpus/frek.poliqarp.corpus.image",
    "corpus/frek.poliqarp.meta-value.offset",
    "corpus/frek.poliqarp.rindex.amb",
    "corpus/frek.poliqarp.rindex.orth.offset",
    "corpus/frek.poliqarp.subpos1.offset",
    "corpus/frek.cfg",
    "corpus/frek.poliqarp.base1.offset",
    "corpus/frek.poliqarp.meta.image",
    "corpus/frek.poliqarp.orth.image",
    "corpus/frek.poliqarp.rindex.amb.offset",
    "corpus/frek.poliqarp.subchunk.image",
    "corpus/frek.poliqarp.subpos2.image",
    "corpus/frek.cfg~",
    "corpus/frek.poliqarp.base2.image",
    "corpus/frek.poliqarp.meta-key.image",
    "corpus/frek.poliqarp.orth.index.alpha",
    "corpus/frek.poliqarp.rindex.disamb",
    "corpus/frek.poliqarp.subchunk.item.ch",
    "corpus/frek.poliqarp.subpos2.offset",
    "corpus/frek.meta.cfg",
    "corpus/frek.poliqarp.base2.offset",
    "corpus/frek.poliqarp.meta-key.offset",
    "corpus/frek.poliqarp.orth.index.atergo",
    "corpus/frek.poliqarp.rindex.disamb.offset",
    "corpus/frek.poliqarp.subchunk.offset",
    "corpus/frek.poliqarp.tag.image",
    "corpus/frek.meta.lisp",
    "corpus/frek.poliqarp.chunk.image",
    "corpus/frek.poliqarp.meta-value.image",
    "corpus/frek.poliqarp.orth.offset",
    "corpus/frek.poliqarp.rindex.orth",
    "corpus/frek.poliqarp.subpos1.image",
    "corpus/frek.poliqarp.tag.offset"
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

