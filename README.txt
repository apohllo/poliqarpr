= poliqarpr

* http://github.com/apohllo/poliqarpr

== DESCRIPTION:

Poliqarpr is Ruby client for Poliqarp server.


== FEATURES/PROBLEMS:

* built-in pagination of query results
* support for lemmatization 
* asynchronous communication might be not stable (100% CPU ussage)
* only partial implementation of server protocol:
** PING, VERSION
** MAKE-SESSION, CLOSE-SESSION
** OPEN (corpus), CLOSE (corpus)
** CORPUS-STATS, GET-TAGSET
** STATUS, CANCEL (used internally)
** MAKE-QUERY, RUN-QUERY, BUFFER-STATE (used internally)
** GET-RESULTS, GET-CONTEXT, METADATA
** SET: lemmata, tags 

== SYNOPSIS:

Poliqarpr is Ruby client for Poliqarp corpus server (see
http://poliqarp.sourceforge.net/), which is used to store large texts used in
Natural Language Processing.
 

== REQUIREMENTS:

Poliqarp server (only C implementation http://poliqarp.sourceforge.net/)

== INSTALL:
 
You need RubyGems v. 1.2 

* gem -v 
* 1.2.0 #=> ok

You need the github.com repository to be added to your sources list:

* gem sources -a http://gems.github.com

Then you can type:

* sudo gem install apohllo-poliqarpr

You can install the optional default corpus (warning: it is distributed under
different license!):

* sudo gem install apohllo-poliqarpr-corpus

== BASIC USAGE: 

(You need the poliqarpr-corpus to be installed for this to work. See the last
step of installation process).

Require the gem:

  require 'poliaqarpr'

Create the server client and open default corpus

  client = Poliqarp::Client.new
  client.open_corpus :default

Query the corpus for given segment
  
  result = client.find("kot")
  result[0].to_s 

Remember to close the client on exit
  
  client.close


== LICENSE:
 
(The MIT License)

Copyright (c) 2008 Aleksander Pohl

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

== FEEDBACK

* mailto:apohllo@o2.pl
