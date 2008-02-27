require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + "/../../id_verification"

module RequestSpecHelper
  def test_subject
    subject = API::IDVerification::Subject.new(
      {
        # basic info
        :firstName => 'Test', 
        :lastName => 'Person', 
        :address => '123 Main St', 
        :city => 'New York', 
        :state => 'NY', 
        :zip => 10001, 
        :ssnLast4 => 1234, 
        :dobMonth => 1, 
        :dobYear => 1980,
        :userID => 1,        
      }
    )
    
    # more for aditional tests
    subject.idNumber = 12345
    subject.verification_questions = test_verification_questions
    subject.challenge_questions = test_challenge_verification_questions


    return subject
  end
  
  def test_verification_questions
    questions = []
    
    # question 1 with answers
    q = API::IDVerification::Question.new
    q.prompt = "TEST - With which name are you associated?"
    q.type = "question.type1"
    q.candidate_answers << API::IDVerification::Answer.new("JANNE")
    q.candidate_answers << API::IDVerification::Answer.new("JESH")
    q.candidate_answers << API::IDVerification::Answer.new("JAVAD")
    q.candidate_answers << API::IDVerification::Answer.new("JOSEPH")
    q.candidate_answers << API::IDVerification::Answer.new("JULES")
    q.candidate_answers << API::IDVerification::Answer.new("None of the above")
    q.chosen_answer = "JANNE"
    questions << q
    
    # question 2 with answers
    q = API::IDVerification::Question.new
    q.prompt = "TEST - Which number goes with your address on CARVER BLVD?"
    q.type = "question.type2"
    q.candidate_answers << API::IDVerification::Answer.new("142")
    q.candidate_answers << API::IDVerification::Answer.new("117")
    q.candidate_answers << API::IDVerification::Answer.new("850")
    q.candidate_answers << API::IDVerification::Answer.new("9101")
    q.candidate_answers << API::IDVerification::Answer.new("504")
    q.candidate_answers << API::IDVerification::Answer.new("None of the above")
    q.chosen_answer = "142"
    questions << q
    
    # question 3 with answers
    q = API::IDVerification::Question.new
    q.prompt = "TEST - Which cross street is near your address on HALBURTON RD?"
    q.type = "question.type3"
    q.candidate_answers << API::IDVerification::Answer.new("MEADOW ST")
    q.candidate_answers << API::IDVerification::Answer.new("BELVOIR BLVD")
    q.candidate_answers << API::IDVerification::Answer.new("LINCOLN ST")
    q.candidate_answers << API::IDVerification::Answer.new("LOCUST AVE")
    q.candidate_answers << API::IDVerification::Answer.new("19TH ST")
    q.candidate_answers << API::IDVerification::Answer.new("None of the above")
    q.chosen_answer = "MEADOW ST"
    questions << q
        
    return questions    
  end

  def test_challenge_verification_questions
    questions = []
    
    # question 1 with answers
    q = API::IDVerification::Question.new
    q.prompt = "TEST CHALLENGE - With which name are you associated?"
    q.type = "question.type1"
    q.candidate_answers << API::IDVerification::Answer.new("JANNE")
    q.candidate_answers << API::IDVerification::Answer.new("JESH")
    q.candidate_answers << API::IDVerification::Answer.new("JAVAD")
    q.candidate_answers << API::IDVerification::Answer.new("JOSEPH")
    q.candidate_answers << API::IDVerification::Answer.new("JULES")
    q.candidate_answers << API::IDVerification::Answer.new("None of the above")
    q.chosen_answer = "JANNE"
    questions << q
    
    # question 2 with answers
    q = API::IDVerification::Question.new
    q.prompt = "TEST CHALLENGE - Which number goes with your address on CARVER BLVD?"
    q.type = "question.type2"
    q.candidate_answers << API::IDVerification::Answer.new("142")
    q.candidate_answers << API::IDVerification::Answer.new("117")
    q.candidate_answers << API::IDVerification::Answer.new("850")
    q.candidate_answers << API::IDVerification::Answer.new("9101")
    q.candidate_answers << API::IDVerification::Answer.new("504")
    q.candidate_answers << API::IDVerification::Answer.new("None of the above")
    q.chosen_answer = "142"
    questions << q
    
    return questions    
  end
  
end

module ResponseSpecHelper
  
  def mock_error_response
    return File.read( File.dirname(__FILE__) + '/fixtures/error_response.xml' )
  end
  
  def mock_unknown_response
    return File.read( File.dirname(__FILE__) + '/fixtures/unknown_response.xml' )
  end
  
  def mock_no_match_response
    return File.read( File.dirname(__FILE__) + '/fixtures/no_match_response.xml' )
  end
  
  def mock_match_found_response
    return File.read( File.dirname(__FILE__) + '/fixtures/match_found_response.xml' )
  end
  
  def mock_match_found_single_address_response
    return File.read( File.dirname(__FILE__) + '/fixtures/match_found_single_address.xml' )
  end
  
  def mock_match_found_ssn_does_not_match_response
    return File.read( File.dirname(__FILE__) + '/fixtures/match_found_ssn_does_not_match.xml' )
  end
  
  def mock_match_found_ssn_invalid_response
    return File.read( File.dirname(__FILE__) + '/fixtures/match_found_ssn_invalid.xml' )
  end
  
  def mock_match_found_ssn_issued_prior_to_dob_response
    return File.read( File.dirname(__FILE__) + '/fixtures/match_found_ssn_issued_prior_to_dob.xml' )
  end
  
  def mock_match_found_ssn_unavailable_response
    return File.read( File.dirname(__FILE__) + '/fixtures/match_found_ssn_unavailable.xml' )
  end
  
  def mock_match_found_subject_deceased_response
    return File.read( File.dirname(__FILE__) + '/fixtures/match_found_subject_deceased.xml' )
  end
  
  def mock_match_found_thin_file_response
    return File.read( File.dirname(__FILE__) + '/fixtures/match_found_thin_file.xml' )
  end  
  
  def mock_questions_response
    return File.read( File.dirname(__FILE__) + '/fixtures/questions_response.xml' )
  end
  
  def mock_verification_timeout_response
    return File.read( File.dirname(__FILE__) + '/fixtures/verification_timeout_response.xml' )
  end
  
  def mock_verification_all_answers_correct_response
    return File.read( File.dirname(__FILE__) + '/fixtures/all_answers_correct_response.xml' )
  end

  def mock_verification_1_answer_incorrect_response
    return File.read( File.dirname(__FILE__) + '/fixtures/1_answer_incorrect_response.xml' )
  end

  def mock_verification_2_answers_incorrect_response
    return File.read( File.dirname(__FILE__) + '/fixtures/2_answers_incorrect_response.xml' )
  end

  def mock_verification_3_answers_incorrect_response
    return File.read( File.dirname(__FILE__) + '/fixtures/3_answers_incorrect_response.xml' )
  end

  def mock_challenge_questions_response
    return File.read( File.dirname(__FILE__) + '/fixtures/challenge_questions_response.xml' )
  end
  
  def mock_challenge_verification_all_answers_correct_response
    return File.read( File.dirname(__FILE__) + '/fixtures/all_answers_correct_challenge_response.xml' )
  end
  
  def mock_challenge_verification_1_answer_incorrect_response
    return File.read( File.dirname(__FILE__) + '/fixtures/one_answer_incorrect_challenge_response.xml' )
  end
  
  def mock_challenge_verification_2_answers_incorrect_response
    return File.read( File.dirname(__FILE__) + '/fixtures/two_answers_incorrect_challenge_response.xml' )
  end

end
