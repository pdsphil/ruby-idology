require File.dirname(__FILE__) + '/spec_helper'

include API::Base
include API::IDVerification

describe Request do
  
  it "should initialize with credentials from config.yml" do
    API::IDVerification::Request.stub!(:config).and_return(File.dirname(__FILE__) + "/../spec/fixtures/sample_config.yml")
    req = API::IDVerification::Request.new
    req.credentials.username.should eql("test_username")
    req.credentials.password.should eql("test_password")
  end
end

describe SearchRequest do
  
  include RequestSpecHelper
  
  before(:each) do
    API::IDVerification::Request.stub!(:config).and_return(File.dirname(__FILE__) + "/../spec/fixtures/sample_config.yml")
    @search_request = SearchRequest.new
  end
  
  it "should initialze with a url" do
    @search_request.url.should eql('https://web.idologylive.com/api/idlive.svc')
  end
  
  it "should initialize with a username and password" do
    @search_request.credentials.username.should eql("test_username")
    @search_request.credentials.password.should eql("test_password")
  end
  
  it "should be able to set its own data given a subject" do
    @search_request.data.should be_nil
    @search_request.set_data(test_subject)
    @search_request.data[:username].should eql("test_username")
    @search_request.data[:password].should eql("test_password")
    @search_request.data[:firstName].should eql("Test")
    @search_request.data[:lastName].should eql("Person")
    @search_request.data[:address].should eql("123 Main St")
    @search_request.data[:city].should eql("New York")
    @search_request.data[:state].should eql("NY")
    @search_request.data[:zip].should eql(10001)
    @search_request.data[:ssnLast4].should eql(1234)
    @search_request.data[:dobMonth].should eql(1)
    @search_request.data[:dobYear].should eql(1980)
    @search_request.data[:uid].should eql(1)
  end
end

describe VerificationQuestionsRequest do
  
  include RequestSpecHelper
  
  before(:each) do
    API::IDVerification::Request.stub!(:config).and_return(File.dirname(__FILE__) + "/../spec/fixtures/sample_config.yml")
    @questions_request = VerificationQuestionsRequest.new
  end
  
  it "should initialze with a url" do
    @questions_request.url.should eql('https://web.idologylive.com/api/idliveq.svc')
  end
  
  it "should initialize with a username and password" do
    @questions_request.credentials.username.should eql("test_username")
    @questions_request.credentials.password.should eql("test_password")
  end
  
  it "should be able to set its own data given a subject" do
    @questions_request.data.should be_nil
    @questions_request.set_data(test_subject)
    @questions_request.data[:username].should eql("test_username")
    @questions_request.data[:password].should eql("test_password")
    @questions_request.data[:idNumber].should eql(12345)
  end

end

describe VerificationRequest do
  
  include RequestSpecHelper
  
  before(:each) do
    API::IDVerification::Request.stub!(:config).and_return(File.dirname(__FILE__) + "/../spec/fixtures/sample_config.yml")
    @verification_request = VerificationRequest.new
  end
  
  it "should initiallize with a url" do
    @verification_request.url.should eql('https://web.idologylive.com/api/idliveq-answers.svc')
  end
  
  it "should initialize with a username and password" do
    @verification_request.credentials.username.should eql("test_username")
    @verification_request.credentials.password.should eql("test_password")
  end
  
  it "should be able to set its own data given a subject" do
    @verification_request.data.should be_nil
    @verification_request.set_data(test_subject)
    @verification_request.data[:username].should eql("test_username")
    @verification_request.data[:password].should eql("test_password")
    @verification_request.data[:idNumber].should eql(12345)
    
    # the question / answer data
    @verification_request.data[:question1Type] = "question.type1"
    @verification_request.data[:question1Answer] = "JANNE"
    @verification_request.data[:question2Type] = "question.type2"
    @verification_request.data[:question2Answer] = "142"
    @verification_request.data[:question3Type] = "question.type3"
    @verification_request.data[:question3Answer] = "MEADOW ST"
  end
  
end

describe ChallengeQuestionsRequest do
  
  include RequestSpecHelper
  
  before(:each) do
    API::IDVerification::Request.stub!(:config).and_return(File.dirname(__FILE__) + "/../spec/fixtures/sample_config.yml")
    @challenge_questions_request = ChallengeQuestionsRequest.new
  end
  
  it "should initialze with a url" do
    @challenge_questions_request.url.should eql('https://web.idologylive.com/api/idliveq-challenge.svc')
  end
  
  it "should initialize with a username and password" do
    @challenge_questions_request.credentials.username.should eql("test_username")
    @challenge_questions_request.credentials.password.should eql("test_password")
  end
  
  it "should be able to set its own data given a subject" do
    @challenge_questions_request.data.should be_nil
    @challenge_questions_request.set_data(test_subject)
    @challenge_questions_request.data[:username].should eql("test_username")
    @challenge_questions_request.data[:password].should eql("test_password")
    @challenge_questions_request.data[:idNumber].should eql(12345)
  end

end

describe ChallengeVerificationRequest do

  include RequestSpecHelper
  
  before(:each) do
    API::IDVerification::Request.stub!(:config).and_return(File.dirname(__FILE__) + "/../spec/fixtures/sample_config.yml")
    @challenge_verification_request = ChallengeVerificationRequest.new    
  end
  
  it "should initiallize with a url" do
    @challenge_verification_request.url.should eql('https://web.idologylive.com/api/idliveq-challenge-answers.svc')
  end
  
  it "should initialize with a username and password" do
    @challenge_verification_request.credentials.username.should eql("test_username")
    @challenge_verification_request.credentials.password.should eql("test_password")
  end
  
  it "should be able to set its own data given a subject" do
    @challenge_verification_request.data.should be_nil
    @challenge_verification_request.set_data(test_subject)
    @challenge_verification_request.data[:username].should eql("test_username")
    @challenge_verification_request.data[:password].should eql("test_password")
    @challenge_verification_request.data[:idNumber].should eql(12345)
    
    # the question / answer data
    @challenge_verification_request.data[:question1Type] = "question.type1"
    @challenge_verification_request.data[:question1Answer] = "JANNE"
    @challenge_verification_request.data[:question2Type] = "question.type2"
    @challenge_verification_request.data[:question2Answer] = "142"
  end

end
