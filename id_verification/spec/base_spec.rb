require File.dirname(__FILE__) + '/spec_helper'

module BaseSpecHelper

  def subject_match_params
    {
      :firstName => 'Mickey',
      :lastName => 'Mouse',
      :address => '123 Main St',
      :city => 'New York',
      :state => 'NY',
      :zip => 10001,
      :ssnLast4 => 1234,
      :dobMonth => 1,
      :dobYear => 1950,
      :userID => 1
    }
  end
  
  def subject_no_match_params
    {
      :firstName => 'DoesNot',
      :lastName => 'Exist',
      :address => '123 Main St',
      :city => 'NoWhere',
      :state => 'NY',
      :zip => 10001,
      :ssnLast4 => 1234,
      :dobMonth => 1,
      :dobYear => 1965      
    }
  end

end

include API::Base
include API::IDVerification

describe BasicAccessCredentials do
  it "should initialize with a username and password hash" do
    credentials = BasicAccessCredentials.new({:username => 'user', :password => 'pass'})
    credentials.username.should eql('user')
    credentials.password.should eql('pass')
  end
end

describe Subject do
  
  include BaseSpecHelper
  include ResponseSpecHelper
  
  it "should initialize with an API Service model" do
    subject = Subject.new
    subject.api_service.should_not be_nil
    subject.api_service.should be_an_instance_of(API::IDVerification::Service)
  end
  
  it "should initialize with optional data" do
    subject = Subject.new(subject_match_params)
    subject.firstName.should eql('Mickey')
    subject.lastName.should eql('Mouse')
    subject.address.should eql('123 Main St')
    subject.state.should eql('NY')
    subject.zip.should eql(10001)
    subject.ssnLast4.should eql(1234)
    subject.dobMonth.should eql(1)
    subject.dobYear.should eql(1950)
  end
  
  it "should be able to locate itself" do
    sub = Subject.new
    sub.set_match.should eql("set to Spider Man")
    
    # avoid a call to the API
    sub.api_service.stub!(:locate).and_return(API::IDVerification::SearchResponse.new(mock_match_found_response))
    sub.locate.should be_true

    sub.eligible_for_verification.should be_true
    sub.idNumber.should eql("5342889")
  end
  
  it "should be able to find its verification questions" do
    sub = Subject.new
    sub.set_match.should eql("set to Spider Man")
    
    # avoid a call to the API
    sub.api_service.stub!(:locate).and_return(SearchResponse.new(mock_match_found_response))
    sub.locate.should be_true
    
    sub.api_service.stub!(:get_questions).and_return(API::IDVerification::VerificationQuestionsResponse.new(mock_questions_response))
    sub.get_questions.should be_true
    
    sub.verification_questions.should_not be_empty
    sub.verification_questions.size.should eql(3)
  end
  
  it "should be able to submit answers to its verification questions" do
    sub = Subject.new
    sub.set_match.should eql("set to Spider Man")
    
    sub.api_service.stub!(:submit_answers).and_return(API::IDVerification::VerificationResponse.new(mock_verification_all_answers_correct_response))
    sub.submit_answers.should be_true
    
    # three correct answers should verify
    sub.verified.should be_true
    sub.challenge.should be_false
  end
  
  it "should be able to determine if it needs challenge questions" do
    sub = Subject.new
    sub.set_match.should eql("set to Spider Man")
    
    sub.api_service.stub!(:submit_answers).and_return(API::IDVerification::VerificationResponse.new(mock_verification_2_answers_incorrect_response))
    sub.submit_answers.should be_true
    
    # 2 incorrect answers gets a challenge
    sub.verified.should be_true
    sub.challenge.should be_true
  end
  
  it "should be able to find its challenge verification questions" do
    sub = Subject.new
    sub.set_match.should eql("set to Spider Man")
    
    sub.api_service.stub!(:get_challenge_questions).and_return(API::IDVerification::ChallengeQuestionsResponse.new(mock_challenge_questions_response))
    sub.get_challenge_questions.should be_true

    sub.challenge_questions.should_not be_empty
    sub.challenge_questions.size.should eql(2)
  end
  
  it "should be able to submit answers to its challenge verification questions" do
    sub = Subject.new
    sub.set_match.should eql("set to Spider Man")
    
    sub.api_service.stub!(:submit_challenge_answers).and_return(
      API::IDVerification::ChallengeVerificationResponse.new(mock_challenge_verification_all_answers_correct_response))
    sub.submit_challenge_answers.should be_true
    
    # two correct answers should pass
    sub.verified.should be_true
  end
  
  it "for debugging, it should be able to set itself to an individual that can be found" do
    sub = Subject.new
    sub.set_match.should eql("set to Spider Man")

    sub.firstName.should eql('Spider')
    sub.lastName.should eql('Man')
    sub.address.should eql('321 Orange Dr')
    sub.city.should eql('Miami')
    sub.state.should eql('FL')
    sub.zip.should eql(33134)
    sub.ssnLast4.should eql(1333)
    sub.dobMonth.should eql(1)
    sub.dobYear.should eql(1950)
  end
  
  it "for debugging, it should be able to set itself to an individual that cannot be found" do
    sub = Subject.new
    sub.set_no_match.should eql("set to DoesNot Exist")

    sub.firstName.should eql('DoesNot')
    sub.lastName.should eql('Exist')
    sub.address.should eql('123 Main St')
    sub.city.should eql('Nowhere')
    sub.state.should eql('NY')
    sub.zip.should eql(10001)
    sub.ssnLast4.should eql(1234)
    sub.dobMonth.should eql(1)
    sub.dobYear.should eql(1965)    
  end
  
  it "should get false when calling locate() and there is an exception" do
    sub = Subject.new
    sub.set_match.should eql("set to Spider Man")
    
    # avoid a call to the API
    sub.api_service.stub!(:locate).and_raise(ServiceError)
    sub.locate.should be_false
  end
  
  it "should get false when calling get_questions() and there is an exception" do
    sub = Subject.new
    sub.set_match.should eql("set to Spider Man")
    
    # avoid a call to the API
    sub.api_service.stub!(:get_questions).and_raise(ServiceError)
    sub.get_questions.should be_false
  end
  
  it "should get false when calling submit_answers() and there is an exception" do
    sub = Subject.new
    sub.set_match.should eql("set to Spider Man")
    
    # avoid a call to the API
    sub.api_service.stub!(:submit_answers).and_raise(ServiceError)
    sub.submit_answers.should be_false
  end
  
  it "should get false when calling get_challenge_questions() and there is an exception" do
    sub = Subject.new
    sub.set_match.should eql("set to Spider Man")
    
    # avoid a call to the API
    sub.api_service.stub!(:get_challenge_questions).and_raise(ServiceError)
    sub.get_challenge_questions.should be_false
  end
  
  it "should get false when calling submit_challenge_answers() and there is an exception" do
    sub = Subject.new
    sub.set_match.should eql("set to Spider Man")
    
    # avoid a call to the API
    sub.api_service.stub!(:submit_challenge_answers).and_raise(ServiceError)
    sub.submit_challenge_answers.should be_false
  end
  
end

describe Service do
  
  include RequestSpecHelper
  include ResponseSpecHelper
  
  before(:each) do
    @service = Service.new
  end
  
  it "should be able to find a subject" do
    @service.stub!(:ssl_post).and_return(mock_match_found_response)
    @service.locate(test_subject).should be_an_instance_of(API::IDVerification::SearchResponse)
    @service.api_search_response.should be_an_instance_of(API::IDVerification::SearchResponse)
  end
  
  it "should be able to get the verification questions for a subject" do
    @service.stub!(:ssl_post).and_return(mock_questions_response)
    @service.get_questions(test_subject).should be_an_instance_of(API::IDVerification::VerificationQuestionsResponse)
    @service.api_question_response.should be_an_instance_of(API::IDVerification::VerificationQuestionsResponse)
  end
  
  it "should be able to submit the answers to verification questions for a subject" do
    @service.stub!(:ssl_post).and_return(mock_verification_all_answers_correct_response)
    @service.submit_answers(test_subject).should be_an_instance_of(API::IDVerification::VerificationResponse)
    @service.api_verification_response.should be_an_instance_of(API::IDVerification::VerificationResponse)
  end
  
  it "should be able to get the challenge verification questions for a subject" do
    @service.stub!(:ssl_post).and_return(mock_challenge_questions_response)
    @service.get_challenge_questions(test_subject).should be_an_instance_of(API::IDVerification::ChallengeQuestionsResponse)
    @service.api_challenge_question_response.should be_an_instance_of(API::IDVerification::ChallengeQuestionsResponse)
  end
  
  it "should be able to submit the answers to challenge verification questions for a subject" do
    @service.stub!(:ssl_post).and_return(mock_challenge_verification_all_answers_correct_response)
    @service.submit_challenge_answers(test_subject).should be_an_instance_of(API::IDVerification::ChallengeVerificationResponse)
    @service.api_challenge_verification_response.should be_an_instance_of(API::IDVerification::ChallengeVerificationResponse)
  end
  
  it "should be able to handle an Exception in locate() when calling the API" do
    @service.stub!(:ssl_post).and_raise(Exception)
    lambda { @service.locate(test_subject) }.should raise_error(ServiceError)
  end
  
  it "should be able to handle an Exception in get_questions() when calling the API" do
    @service.stub!(:ssl_post).and_raise(Exception)
    lambda { @service.get_questions(test_subject) }.should raise_error(ServiceError)
  end
  
  it "should be able to handle an Exception in submit_answers() when calling the API" do
    @service.stub!(:ssl_post).and_raise(Exception)
    lambda { @service.submit_answers(test_subject) }.should raise_error(ServiceError)    
  end
  
  it "should be able to handle an Exception in get_challenge_questions() when calling the API" do
    @service.stub!(:ssl_post).and_raise(Exception)
    lambda { @service.get_challenge_questions(test_subject) }.should raise_error(ServiceError)
  end
  
  it "should be able to handle an Exception in submit_challenge_answers() when calling the API" do
    @service.stub!(:ssl_post).and_raise(Exception)
    lambda { @service.submit_challenge_answers(test_subject) }.should raise_error(ServiceError)
  end
end
