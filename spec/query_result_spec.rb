require File.join(File.dirname(__FILE__), '..','lib','poliqarp')

describe Poliqarp::QueryResult do
  before(:all) do
    @client = Poliqarp::Client.new("TEST")
    @client.open_corpus(:default)
  end

  after(:all) do
    @client.close
  end

  describe "(for unspecified query)" do 
    before(:all) do
      @result = @client.find("kot")
    end

    it "should not be nil" do
      @result.should_not == nil
    end

    it "should containt its size" do
      @result.size.should_not == nil
    end

    it "should be iterable" do
      @result.each do |excerpt|
        excerpt.should_not == nil
      end
    end

    it "should allow to add excerpt" do
      @result << Poliqarp::Excerpt.new(0,@client, "abc")
    end

    it "should contain current page" do
      @result.page.should_not == nil
    end

    it "should contain the page count" do
      @result.page_count.should_not == nil
    end

    it "should allow to call previous page" do
      @result.previous_page
    end

    it "should allow to call next page" do
      @result.next_page
    end
  end

  describe "(for 'kot' in :default corpus)" do
    before(:all) do 
      @result = @client.find("kot")
    end

    it "should have size == 6" do 
      @result.size.should == 6
    end

    it "should have page set to 1" do
      @result.page.should == 1
    end

    it "should contain only one page" do
      @result.page_count.should == 1
    end

    it "should not have previous page" do
      @result.previous_page.should == nil
    end

    it "should not have next page" do
      @result.next_page.should == nil
    end
  end

  describe "(for 'kot' with page_size set to 5 in :default corpus)" do
    before(:all) do 
      @result = @client.find("kot", :page_size => 5)
    end

    it "should have size == 5" do  
      @result.size.should == 5
    end

    it "should have page set to 1" do
      @result.page.should == 1
    end

    it "should contain 2 pages" do
      @result.page_count.should == 2
    end

    it "should not have previous page" do
      @result.previous_page.should == nil
    end

    it "should have next page" do
      @result.next_page.should_not == nil
    end
  end

  describe "(next for 'kot' with page_size set to 5 in :default corpus)" do
    before(:all) do 
      @result = @client.find("kot", :page_size => 5).next_page
    end

    it "should have size == 1" do  
      @result.size.should == 1
    end

    it "should have page set to 2" do
      @result.page.should == 2
    end

    it "should contain 2 pages" do
      @result.page_count.should == 2
    end

    it "should have previous page" do
      @result.previous_page.should_not == nil
    end

    it "should not have next page" do
      @result.next_page.should == nil
    end
  end
end
