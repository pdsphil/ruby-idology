require File.dirname(__FILE__) + '/spec_helper'

include API::IDVerification

describe Response do
  
  include ResponseSpecHelper
  
  it "should check for an error from the API" do
    response = Response.new(mock_error_response)
    response.result_key.should eql("error")
    response.result_message.should eql("Your IP address is not registered. Please call IDology Customer Service (770-984-4697).")
  end
  
  it "should return an error message if the API response is not understood" do
    response = Response.new(mock_unknown_response)
    response.result_key.should eql("error")
    response.result_message.should eql("The API returned an unexpected error.")
  end
  
  it "should store the results key, message, and ID from any non-error response" do
    response = Response.new(mock_no_match_response)
    response.result_key.should eql("result.no.match")
    response.result_message.should eql("ID Not Located")
    response.id_number.should eql("5342330")
  end
    
end

describe SearchResponse do
  
  include ResponseSpecHelper
  
  it "should be eligible_for_verification? if there is a match" do
    search = SearchResponse.new(mock_match_found_response)
    search.result_key.should eql("result.match")
    search.result_message.should eql("ID Located")
    search.id_number.should eql("5342889")
    search.eligible_for_verification?.should be_true
  end
  
  it "should not be eligible_for_verification? if there is no match" do
    search = SearchResponse.new(mock_no_match_response)
    search.result_key.should eql("result.no.match")
    search.result_message.should eql("ID Not Located")
    search.id_number.should eql("5342330")
    search.eligible_for_verification?.should be_false
  end
  
  it "should not be eligible_for_verification? if the response qualifiers note 'Single Address in File'" do
    search = SearchResponse.new(mock_match_found_single_address_response)
    search.id_number.should eql("5922430")
    search.qualifiers.keys.include?("resultcode.single.address").should be_true
    search.qualifiers["resultcode.single.address"].should eql("Single Address in File")
    search.eligible_for_verification?.should be_false
  end
  
  it "should not be eligible_for_verification? if the response qualifiers note 'SSN4 Does Not Match'" do
    search = SearchResponse.new(mock_match_found_ssn_does_not_match_response)
    search.id_number.should eql("5922430")
    search.qualifiers.keys.include?("resultcode.ssn.does.not.match").should be_true
    search.qualifiers["resultcode.ssn.does.not.match"].should eql("SSN4 Does Not Match")
    search.eligible_for_verification?.should be_false
  end
  
  it "should not be eligible_for_verification? if the response qualifiers note 'SSN Is Invalid'" do
    search = SearchResponse.new(mock_match_found_ssn_invalid_response)
    search.id_number.should eql("5922430")
    search.qualifiers.keys.include?("resultcode.ssn.invalid").should be_true
    search.qualifiers["resultcode.ssn.invalid"].should eql("SSN Is Invalid")
    search.eligible_for_verification?.should be_false
  end
  
  it "should not be eligible_for_verification? if the response qualifiers note 'SSN Issued Prior to DOB'" do
    search = SearchResponse.new(mock_match_found_ssn_issued_prior_to_dob_response)
    search.id_number.should eql("5922430")
    search.qualifiers.keys.include?("resultcode.ssn.issued.prior.to.dob").should be_true
    search.qualifiers["resultcode.ssn.issued.prior.to.dob"].should eql("SSN Issued Prior to DOB")
    search.eligible_for_verification?.should be_false
  end
  
  it "should not be eligible_for_verification? if the response qualifiers note 'SSN unavailable'" do
    search = SearchResponse.new(mock_match_found_ssn_unavailable_response)
    search.id_number.should eql("5922430")
    search.qualifiers.keys.include?("resultcode.ssn.not.available").should be_true
    search.qualifiers["resultcode.ssn.not.available"].should eql("SSN unavailable")
    search.eligible_for_verification?.should be_false
  end
  
  it "should not be eligible_for_verification? if the response qualifiers note 'Subject is Deceased'" do
    search = SearchResponse.new(mock_match_found_subject_deceased_response)
    search.id_number.should eql("5922430")
    search.qualifiers.keys.include?("resultcode.subject.deceased").should be_true
    search.qualifiers["resultcode.subject.deceased"].should eql("Subject is Deceased")
    search.eligible_for_verification?.should be_false
  end
  
#  it "should not be eligible_for_verification? if the response qualifiers note 'Thin File'" do
#    search = SearchResponse.new(mock_match_found_thin_file_response)
#    search.id_number.should eql("5922430")
#    search.qualifiers.keys.include?("resultcode.thin.file").should be_true
#    search.qualifiers["resultcode.thin.file"].should eql("Thin File")
#    search.eligible_for_verification?.should be_false
#  end
  
end

describe VerificationQuestionsResponse do
  
  include ResponseSpecHelper
  
  it "should be able to parse the questions returned" do
    q_response = VerificationQuestionsResponse.new(mock_questions_response)
    q_response.result_key.should eql("result.match")
    q_response.result_message.should eql("ID Located")
    q_response.id_number.should eql("5343388")
    q_response.questions.should_not be_empty
    q_response.questions.size.should eql(3)
  end
    
  it "should not have any questions if none are returned" do
    q_response = VerificationQuestionsResponse.new(mock_match_found_response) # invalid question response
    q_response.result_key.should eql("result.match")
    q_response.result_message.should eql("ID Located")
    q_response.id_number.should eql("5342889")
    q_response.questions.should be_nil
  end
  
  it "should be able to parse the questions correctly" do
    q_response = VerificationQuestionsResponse.new(mock_questions_response)
    
    # from the questions_response.xml fixture - three questions
    question = q_response.questions.find {|q| q.prompt == "With which name are you associated?"}
    question.should_not be_nil
    question.type.should eql("alternate.names.phone")
    
    question = q_response.questions.find {|q| q.prompt == "Where was your social security number issued?"}
    question.should_not be_nil
    question.type.should eql("ssn.issued.in")
    
    question = q_response.questions.find {|q| q.prompt == "In which county have you lived?"}
    question.should_not be_nil
    question.type.should eql("current.county")
  end
  
  it "should be able to parse the answers correctly" do
    q_response = VerificationQuestionsResponse.new(mock_questions_response)
    
    # from the questions_response.xml fixture - three questions with six answers each
    answers = q_response.questions.find {|q| q.prompt == "With which name are you associated?"}.candidate_answers
    answers.find {|a| a.text == "ENDO"}.should_not be_nil
    answers.find {|a| a.text == "ENRIQUEZ"}.should_not be_nil
    answers.find {|a| a.text == "EATON"}.should_not be_nil
    answers.find {|a| a.text == "ECHOLS"}.should_not be_nil
    answers.find {|a| a.text == "EPPS"}.should_not be_nil
    answers.find {|a| a.text == "None of the above"}.should_not be_nil

    answers = q_response.questions.find {|q| q.prompt == "Where was your social security number issued?"}.candidate_answers
    answers.find {|a| a.text == "Michigan"}.should_not be_nil
    answers.find {|a| a.text == "Wyoming"}.should_not be_nil
    answers.find {|a| a.text == "Arkansas"}.should_not be_nil
    answers.find {|a| a.text == "North Carolina"}.should_not be_nil
    answers.find {|a| a.text == "Illinois"}.should_not be_nil
    answers.find {|a| a.text == "None of the above"}.should_not be_nil
    
    answers = q_response.questions.find {|q| q.prompt == "In which county have you lived?"}.candidate_answers
    answers.find {|a| a.text == "PICKENS"}.should_not be_nil
    answers.find {|a| a.text == "ST MARY"}.should_not be_nil
    answers.find {|a| a.text == "FRANKLIN"}.should_not be_nil
    answers.find {|a| a.text == "ANDREWS"}.should_not be_nil
    answers.find {|a| a.text == "MIAMI"}.should_not be_nil
    answers.find {|a| a.text == "None of the above"}.should_not be_nil    
  end
end

describe VerificationResponse do
  
  include ResponseSpecHelper
  
  it "should be able to handle a timeout response" do
    v_response = VerificationResponse.new(mock_verification_timeout_response)
    v_response.idliveq_result_key.should eql("result.timeout")
    v_response.idliveq_result_message.should eql("result.timeout")
  end
  
  it "should be able to handle an all answers correct response" do
    v_response = VerificationResponse.new(mock_verification_all_answers_correct_response)
    v_response.idliveq_result_key.should eql("result.questions.0.incorrect")
    v_response.idliveq_result_message.should eql("All Answers Correct")
    v_response.verified?.should be_true
    v_response.challenge?.should be_false
  end
  
  it "should be able to handle a 1 answer incorrect response" do
    v_response = VerificationResponse.new(mock_verification_1_answer_incorrect_response)
    v_response.idliveq_result_key.should eql("result.questions.1.incorrect")
    v_response.idliveq_result_message.should eql("One Incorrect Answer")
    v_response.verified?.should be_true
    v_response.challenge?.should be_false
  end
  
  it "should be able to handle a 2 answers incorrect response" do
    v_response = VerificationResponse.new(mock_verification_2_answers_incorrect_response)
    v_response.idliveq_result_key.should eql("result.questions.2.incorrect")
    v_response.idliveq_result_message.should eql("Two Incorrect Answers")
    v_response.verified?.should be_true
    v_response.challenge?.should be_true
  end
  
  it "should be able to handle a 3 answers incorrect response" do
    v_response = VerificationResponse.new(mock_verification_3_answers_incorrect_response)
    v_response.idliveq_result_key.should eql("result.questions.3.incorrect")
    v_response.idliveq_result_message.should eql("Three Incorrect Answers")
    v_response.verified?.should be_false
    v_response.challenge?.should be_false
  end
  
end

describe ChallengeQuestionsResponse do
  
  include ResponseSpecHelper
  
  it "should be able to parse the questions returned" do
    q_response = ChallengeQuestionsResponse.new(mock_challenge_questions_response)
    q_response.result_key.should eql("result.match")
    q_response.result_message.should eql("Pass")
    q_response.id_number.should eql("5444900")
    q_response.questions.should_not be_empty
    q_response.questions.size.should eql(2) # only two questions sent back for challenge
  end

  it "should be able to parse the questions correctly" do
    q_response = ChallengeQuestionsResponse.new(mock_challenge_questions_response)
    
    # from the questions_response.xml fixture - three questions
    question = q_response.questions.find {|q| q.prompt == "Which of the following people do you know?"}
    question.should_not be_nil
    question.type.should eql("person.known")
    
    question = q_response.questions.find {|q| q.prompt == "Which street goes with your address number 840?"}
    question.should_not be_nil
    question.type.should eql("street.name")
  end
  
  it "should be able to parse the answers correctly" do
    q_response = ChallengeQuestionsResponse.new(mock_challenge_questions_response)
    
    # from the questions_response.xml fixture - three questions with six answers each
    answers = q_response.questions.find {|q| q.prompt == "Which of the following people do you know?"}.candidate_answers
    answers.find {|a| a.text == "FREDDY JEFFERS"}.should_not be_nil
    answers.find {|a| a.text == "ARTHUR DAVIS"}.should_not be_nil
    answers.find {|a| a.text == "KACIE JACKSON"}.should_not be_nil
    answers.find {|a| a.text == "KRISTA GRIFFIN"}.should_not be_nil
    answers.find {|a| a.text == "MIRIAIN SANCHEZ"}.should_not be_nil
    answers.find {|a| a.text == "None of the above"}.should_not be_nil

    answers = q_response.questions.find {|q| q.prompt == "Which street goes with your address number 840?"}.candidate_answers
    answers.find {|a| a.text == "ROBBIE VW"}.should_not be_nil
    answers.find {|a| a.text == "LUBICH DR"}.should_not be_nil
    answers.find {|a| a.text == "VICTOR WAY"}.should_not be_nil
    answers.find {|a| a.text == "VARSITY CT"}.should_not be_nil
    answers.find {|a| a.text == "VAQUERO DR"}.should_not be_nil
    answers.find {|a| a.text == "None of the above"}.should_not be_nil    
  end
end

describe ChallengeVerificationResponse do
  
  include ResponseSpecHelper
  
  it "should be able to handle an all answers correct response" do
    v_response = ChallengeVerificationResponse.new(mock_challenge_verification_all_answers_correct_response)
    v_response.idliveq_challenge_result_key.should eql("result.challenge.0.incorrect")
    v_response.idliveq_challenge_result_message.should eql("result.challenge.0.incorrect")
    v_response.verified?.should be_true
  end
  
  it "should be able to handle a 1 answer incorrect response" do
    v_response = ChallengeVerificationResponse.new(mock_challenge_verification_1_answer_incorrect_response)
    v_response.idliveq_challenge_result_key.should eql("result.challenge.1.incorrect")
    v_response.idliveq_challenge_result_message.should eql("result.challenge.1.incorrect")
    v_response.verified?.should be_false
  end
  
  it "should be able to handle a 2 answers incorrect response" do
    v_response = ChallengeVerificationResponse.new(mock_challenge_verification_2_answers_incorrect_response)
    v_response.idliveq_challenge_result_key.should eql("result.challenge.2.incorrect")
    v_response.idliveq_challenge_result_message.should eql("result.challenge.2.incorrect")
    v_response.verified?.should be_false
  end  
end

describe Question do
  it "should initialize with empty values" do
    question = Question.new
    question.prompt.should eql("")
    question.type.should eql("")
    question.candidate_answers.should eql([])
    question.chosen_answer.should be_nil
  end
end

describe Answer do
  it "should initialize with a value" do
    answer = Answer.new("test")
    answer.text.should eql("test")
  end
end