require File.join(File.dirname(__FILE__), '..','lib','poliqarp')

describe Poliqarp::Excerpt do
  before(:all) do
    @client = Poliqarp::Client.new("TEST")
  end

  after(:all) do
    @client.close
  end

  describe "(unspecified excerpt)" do
    before(:all) do
      @client.open_corpus(:default)
      @excerpt = @client.find("kot").first
    end

    it "should have index" do
      @excerpt.index.should_not == nil
    end

    it "should have base form" do 
      @excerpt.base_form.should_not == nil
    end

    it "should allow to add short context" do
      @excerpt << "abc"
    end

    it "should contain the exact form which it was created for" do
      @excerpt.inflected_form.should_not == nil
    end

    it "should contain the long context of the word" do
      @excerpt.context.should_not == nil
    end
  end

  describe "(first exceprt for 'kot' in 'sample' corpus)" do
    before(:all) do
      @client.open_corpus("/home/fox/local/poliqarp/2.sample.30/sample")
      @excerpt = @client.find("kot").first
    end

    it "should have index set to 0" do
      @excerpt.index.should == 0 
    end

    it "should have base form set to 'kot'" do 
      @excerpt.base_form.should == "kot"
    end

    it "should have 'kot' as inflected form  " do
      @excerpt.inflected_form.should_not == nil
    end

    it "should contain the long context of the word" do
      @excerpt.context.to_s.size.should >  10
    end

    it "should have one 'medium' set to 'książka'" do
      @excerpt.medium.size.should == 1
      @excerpt.medium[0].should == "książka"
    end

    it "should have 2 'styles' set to 'naukowo-dydaktyczny' and 'naukowo-humanistyczny'" do
      @excerpt.style.size.should == 2
      @excerpt.style.include?("naukowo-dydaktyczny")
      @excerpt.style.include?("naukowo-humanistyczny")
    end

    it "should have 'date' set to nil" do
      @excerpt.date.should == nil
    end

    it "should have 'city' set to nil" do
      @excerpt.city.should == nil
    end
    
    it "should have one 'publisher' set to 'Wydawnictwo Naukowe Akademii Pedagogicznej'" do
      @excerpt.publisher.size.should == 1
      @excerpt.publisher[0].should == "Wydawnictwo Naukowe Akademii Pedagogicznej"
    end

    it "should have one 'title' set to 'Wczesne nauczanie języków obcych. Integracja języka obcego z przedmiotami artystycznymi w młodszych klasach szkoły podstawowej'" do
      @excerpt.title.size.should == 1
      @excerpt.title[0].should == "Wczesne nauczanie języków obcych. Integracja języka obcego z przedmiotami artystycznymi w młodszych klasach szkoły podstawowej"
    end

    it "should have one 'author' set to 'Małgorzata Pamuła'" do
      @excerpt.author.size.should == 1
      @excerpt.author[0].should == "Małgorzata Pamuła"
    end
  end
end