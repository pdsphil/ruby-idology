require 'net/http'
require 'net/https'
require 'logger'

module API
  module IDVerification
    
    class Service
      include API::Base # for error classes
      
      attr_accessor :api_search_response, :api_question_response, :api_verification_response, :api_challenge_question_response, :api_challenge_verification_response
      
      def locate(subject)
        # locate is an IDology ExpectID API call - only checks to see if a person is available in the system
        # if available, further API calls can be made to verify the person's identity via ExpectID IQ questions
        
        # new SearchRequest Object
        search_request = API::IDVerification::SearchRequest.new
        
        # assemble the data in a hash for the POST
        search_request.set_data(subject)
        
        # make the call
        response = API::IDVerification::SearchResponse.new( ssl_post(search_request.url, search_request.data) )
        self.api_search_response = response
        
        return response
        
      rescue Exception => err
        log_error(err, 'locate()')
        
        # raise a generic error for the caller
        raise ServiceError
      end
      
      def get_questions(subject)
        # get_questions is an IDology ExpectID IQ API call - which given a valid idNumber from an ExpectID API call
        # should return three questions that can be asked to verify the ID of the person in question
        
        # new VerificationQuestionsRequest object
        question_request = API::IDVerification::VerificationQuestionsRequest.new
        
        # assemble the data in a hash for the POST
        question_request.set_data(subject)
        
        # make the call
        response = API::IDVerification::VerificationQuestionsResponse.new( ssl_post(question_request.url, question_request.data) )
        self.api_question_response = response
                
        return response
        
      rescue Exception => err
        log_error(err, 'get_questions()')
        
        # raise a generic error for the caller
        raise ServiceError
      end
      
      def submit_answers(subject)
        # submit questions / answers to the IDology ExpectID IQ API
        
        verification_request = API::IDVerification::VerificationRequest.new
        
        # assemble the data for POST
        verification_request.set_data(subject)
        
        # make the call
        response = API::IDVerification::VerificationResponse.new( ssl_post(verification_request.url, verification_request.data) )
        self.api_verification_response = response
        
        return response
        
      rescue Exception => err
        log_error(err, 'submit_answers()')
        
        # raise a generic error for the caller
        raise ServiceError
      end
      
      def get_challenge_questions(subject)
        # get_challenge_questions is an IDology ExpectID Challenge API call - given a valid idNumber from an ExpectID IQ question
        # and response process, will return questions to further verify the subject
        
        question_request = API::IDVerification::ChallengeQuestionsRequest.new
        
        # assemble the data
        question_request.set_data(subject)
        
        # make the call
        response = API::IDVerification::ChallengeQuestionsResponse.new( ssl_post(question_request.url, question_request.data) )
        self.api_challenge_question_response = response
        
        return response
        
      rescue Exception => err
        log_error(err, 'get_challenge_questions()')
        
        # raise a generic error for the caller
        raise ServiceError
      end
      
      def submit_challenge_answers(subject)
        # submit question type / answers to the IDology ExpectID Challenge API
        
        challenge_verification_request = API::IDVerification::ChallengeVerificationRequest.new
        
        # assemble the data
        challenge_verification_request.set_data(subject)
        
        # make the call
        response = API::IDVerification::ChallengeVerificationResponse.new( ssl_post(challenge_verification_request.url, challenge_verification_request.data) )
        self.api_challenge_verification_response = response
        
        return response
        
      rescue Exception => err
        log_error(err, 'submit_challenge_answers()')
        
        # raise a generic error for the caller
        raise ServiceError
      end
      
      
      private
      
      def ssl_post(url, data, headers = {})
        url = URI.parse(url)

        # create a Proxy class, incase a proxy is being used - will work even if proxy options are nil
        connection = Net::HTTP.new(url.host, url.port)
        
        connection.use_ssl = true
        
        if ENV['RAILS_ENV'] == 'production'
          # we want SSL enforced via certificates
          connection.verify_mode = OpenSSL::SSL::VERIFY_PEER
          connection.ca_file = File.dirname(__FILE__) + "/certs/cacert.pem"
        else
          # do not enforce SSL in dev modes
          connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
          
          # for debugging
          connection.set_debug_output $stderr
        end
        
        connection.start { |https|
          # setup the POST request
          req = Net::HTTP::Post.new(url.path)
          req.set_form_data(data, '&')
          
          # do the POST and return the response body
          return https.request(req).body
        }
      end

      def log_error(err, method_name)
        logger = Logger.new(File.dirname(__FILE__) + "/log/error.log")
        logger.error "IDology API Error in Service.#{method_name} - " + err.message
        logger.close
      end
    end
    
    class Subject
      include API::Base # for error classes
      
      attr_accessor :firstName, :lastName, :address, :city, :state, :zip, :ssnLast4, :dobMonth, :dobYear, :userID
      attr_accessor :idNumber, :api_service, :qualifiers
      attr_accessor :verification_questions, :eligible_for_verification, :verified, :challenge
      attr_accessor :challenge_questions
      
      def initialize(data = nil)
        self.api_service = API::IDVerification::Service.new
        self.verified = self.challenge = self.eligible_for_verification = false
        self.qualifiers = ""
        
        if data
          self.firstName = data[:firstName]
          self.lastName = data[:lastName]
          self.address = data[:address]
          self.city = data[:city]
          self.state = data[:state]
          self.zip = data[:zip]
          self.ssnLast4 = data[:ssnLast4]
          self.dobMonth = data[:dobMonth]
          self.dobYear = data[:dobYear]
          self.userID = data[:userID]
        end
      end
      
      def locate
        response = self.api_service.locate(self)
        
        self.idNumber = response.id_number
        self.eligible_for_verification = response.eligible_for_verification?
        
        # we must track any qualifiers that come back
        if ! response.qualifiers.empty?
          self.qualifiers = response.qualifiers.values.join("|")
        end
        
        return true
        
      rescue ServiceError
        return false
      end
      
      def get_questions
        response = self.api_service.get_questions(self)
        self.verification_questions = response.questions
        
        return true
        
      rescue ServiceError
        return false
      end
      
      def submit_answers
        response = self.api_service.submit_answers(self)
        self.verified = response.verified?
        self.challenge = response.challenge?
        
        return true
        
      rescue ServiceError
        return false
      end
      
      def get_challenge_questions
        response = self.api_service.get_challenge_questions(self)
        self.challenge_questions = response.questions
        
        return true
        
      rescue ServiceError
        return false
      end
      
      def submit_challenge_answers
        response = self.api_service.submit_challenge_answers(self)
        self.verified = response.verified?
        
        return true
        
      rescue ServiceError
        return false
      end
      
      
      # for debugging
      def set_match
        # this is a test record that will be found
        self.firstName = 'Spider'
        self.lastName = 'Man'
        self.address = '321 Orange Dr'
        self.city = 'Miami'
        self.state = 'FL'
        self.zip = 33134
        self.ssnLast4 = 1333
        self.dobMonth = 1
        self.dobYear = 1950
        
        return "set to Spider Man"
      end
      
      def set_no_match
        # this guy does not exist
        self.firstName = 'DoesNot'
        self.lastName = 'Exist'
        self.address = '123 Main St'
        self.city = 'Nowhere'
        self.state = 'NY'
        self.zip = 10001
        self.ssnLast4 = 1234
        self.dobMonth = 1
        self.dobYear = 1965
        
        return "set to DoesNot Exist"
      end
      
      def show_questions
        # display the question.prompt and question.candidate_answers
        if ! self.verification_questions.empty?
          count = 0
          self.verification_questions.each do |question|
            puts count.to_s + " - " + question.prompt + ": \n"
            
            question.candidate_answers.each do |answer|
              puts "   - " + answer.text + "\n"
            end
            
            count += 1
          end
        end
        
        return "\n"
      end

      def show_challenge_questions
        # display the question.prompt and question.candidate_answers
        if ! self.challenge_questions.empty?
          count = 0
          self.challenge_questions.each do |question|
            puts count.to_s + " - " + question.prompt + ": \n"
            
            question.candidate_answers.each do |answer|
              puts "   - " + answer.text + "\n"
            end
            
            count += 1
          end
        end
        
        return "\n"
      end
      
    end
    
  end
end