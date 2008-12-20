require File.join(File.dirname(__FILE__), '..','lib','poliqarpr')

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
  end

  describe "(with 'sample' corpus)" do
    before(:all) do
      @client = Poliqarp::Client.new("TEST")
      @client.open_corpus("/home/fox/local/poliqarp/2.sample.30/sample")
    end

    after(:all) do
      @client.close
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
