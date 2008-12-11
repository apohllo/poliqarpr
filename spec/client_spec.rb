require File.join(File.dirname(__FILE__), '..','lib','poliqarp')

describe Poliqarp::Client do
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

  describe "(with open corpus)" do
    before(:each) do
      @client.open_corpus("/home/fox/local/poliqarp/2.sample.30/sample")
    end

    it "should allow to find 'kot'" do 
      @client.find("kot").should_not == nil
    end

    it "should allow to query for term occurences" do
      @client.count("kot").should_not == nil
    end

    it "should return 188 occurences of 'kot'" do
      @client.count("kot").should == 188
    end
    
  end

end
