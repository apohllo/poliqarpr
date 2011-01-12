#vim:encoding=utf-8
$:.unshift("lib")
require 'poliqarpr'

describe Poliqarp::Client do
  describe "(general test)" do
    before(:each) do
      @client = Poliqarp::Client.new("TEST")
    end
    
    after(:each) do 
      @client.close
    end
  
    it "should allow to open corpus" do
      @client.open_corpus("/home/fox/local/poliqarp/2.sample.30/sample")
    end
  
    it "should allow to open :default corpus" do
      @client.open_corpus(:default)
    end

    it "should respond to :ping" do
      @client.ping.should == :pong
    end

    it "should return server version" do
      @client.version.should_not == nil
    end

  end

  describe "(with 'sample' corpus)" do
    before(:all) do
      @client = Poliqarp::Client.new("TEST")
      @client.open_corpus("/home/fox/local/poliqarp/2.sample.30/sample")
    end

    after(:all) do
      @client.close
    end

    it "should allow to set the right context size" do 
      @client.right_context = 5
    end

    it "should raise error if the size of right context is not number" do 
      (proc do 
        @client.right_context = "a"
      end).should raise_error(RuntimeError)
    end

    it "should rais error if the size of right context is less or equal 0" do 
      (proc do 
        @client.right_context = 0
      end).should raise_error(RuntimeError)
    end

    it "should allow to set the left context size" do 
      @client.right_context = 5
    end

    it "should raise error if the size of left context is not number" do 
      (lambda do 
        @client.left_context = "a"
      end).should raise_error(RuntimeError)
    end

    it "should rais error if the size of left context is less or equal 0" do 
      (lambda do 
        @client.left_context = 0
      end).should raise_error(RuntimeError)
    end

    it "should return corpus statistics" do
      stats = @client.stats
      stats.size.should == 4
      [:segment_tokens, :segment_types, :lemmata, :tags].each do |type|
        stats[type].should_not == nil
        stats[type].should > 0
      end
    end

    it "should return the corpus tagset" do
      tagset = @client.tagset
      tagset[:categories].should_not == nil
      tagset[:classes].should_not == nil
    end

    it "should allow to find 'kot'" do 
      @client.find("kot").size.should_not == 0
    end

    it "should contain 'kot' in query result for [base=kot]" do
      @client.find("[base=kot]")[0].to_s.should match(/\bkot\b/)
    end

    it "should allow to find 'Afrodyta [] od" do
      @client.find("Afrodyta [] od").size.should_not == 0
    end

    it "should contain 'Afrodyta .* od' for 'Afrodyta [] od' query " do
      @client.find("Afrodyta [] od")[0].to_s.should match(/Afrodyta .* od/)
    end

    it "should return collection for find without index specified" do
      @client.find("kot").should respond_to(:[])
    end

    it "should allow to query for term occurences" do
      @client.count("kot").should_not == nil
    end

    it "should return 188 occurences of 'kot'" do
      @client.count("kot").should == 188
    end

    it "should allow to find first occurence of 'kot'" do
      @client.find("kot",:index => 0).should_not == nil
    end

    it "should return different results for different queries" do
      @client.find("kot").should_not ==
        @client.find("kita")
    end

    it "should return same results for same queries" do
      @client.find("kita").should == @client.find("kita")
    end

    describe("(with index specified in find)") do
      before(:each) do 
        @result = @client.find("nachalny",:index => 0)
      end

      it "should not return collection for find" do
        @result.should_not respond_to(:[])
      end

      it "should not be nil" do
        @result.should_not == nil
      end

      it "should fetch the same excerpt as in find without index " do
        @result.to_s.should == @client.find("nachalny")[0].to_s
      end
    end

    describe("(with lemmata flags set to true)") do 
      before(:all) do
        @client.lemmata = {:left_context => true, :right_context => true,
          :left_match => true, :right_match => true}
      end

      it "should allow to find 'kotu'" do 
        @client.find("kotu").size.should_not == 0
      end

      it "should contain 'kotu' in query result for 'kotu'" do
        @client.find("kotu")[0].to_s.should match(/\bkotu\b/)
      end

      it "should contain 'kot' in lemmatized query result for 'kotu'" do
        @client.find("kotu")[0].short_context.flatten.
          map{|e| e.lemmata[0].base_form}.join(" ").should match(/\bkot\b/)
      end

    end
  end

end
