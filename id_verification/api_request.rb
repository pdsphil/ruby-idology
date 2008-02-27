require 'yaml'

module API
  module IDVerification
    
    class Request < API::Base::Request
      attr_accessor :data
      
      class << self
        attr_accessor :config
      end      
      
      # test for config file
      if ! File.exist?(File.dirname(__FILE__) + "/config.yml")
        raise Exception, "config file for API::IDVerification not present - try reading the README file"
      end
      
      # must be in the same directory as this file
      self.config = File.dirname(__FILE__) + "/config.yml"
      
      def initialize
        config = YAML::load(File.open(Request.config))
        self.credentials = API::Base::BasicAccessCredentials.new(:username => config['username'], :password => config['password'])
      end
      
    end
    
    class SearchRequest < Request
      
      def initialize
        # corresponds to an IDology ExpectID API call
        self.url = 'https://web.idologylive.com/api/idlive.svc'
        
        super
      end
      
      def set_data(subject)
        data_to_send = {
          :username => self.credentials.username, 
          :password => self.credentials.password, 
          :firstName => subject.firstName, 
          :lastName => subject.lastName, 
          :address => subject.address, 
          :city => subject.city, 
          :state => subject.state, 
          :zip => subject.zip, 
          :ssnLast4 => subject.ssnLast4, 
          :dobMonth => subject.dobMonth, 
          :dobYear => subject.dobYear, 
          :uid => subject.userID
        }
        
        self.data = data_to_send
      end
    end
    
    class VerificationQuestionsRequest < Request
      
      def initialize
        # corresponds to an IDology ExpectID IQ API call
        self.url = 'https://web.idologylive.com/api/idliveq.svc'
        
        super
      end
      
      def set_data(subject)
        data_to_send = {
          :username => self.credentials.username, 
          :password => self.credentials.password, 
          :idNumber => subject.idNumber
        }
        
        self.data = data_to_send
      end
    end

    class ChallengeQuestionsRequest < Request
      
      def initialize
        # corresponds to an IDology ExpectID Challenge API call
        self.url = 'https://web.idologylive.com/api/idliveq-challenge.svc'
        
        super
      end
      
      def set_data(subject)
        data_to_send = {
          :username => self.credentials.username, 
          :password => self.credentials.password, 
          :idNumber => subject.idNumber
        }
        
        self.data = data_to_send
      end
    end
    
    class VerificationRequest < Request
      
      def initialize
        # corresponds to an IDology ExpectID IQ API call
        self.url = 'https://web.idologylive.com/api/idliveq-answers.svc'
        
        super
      end
      
      def set_data(subject)
        data_to_send = {
          :username => self.credentials.username, 
          :password => self.credentials.password, 
          :idNumber => subject.idNumber
        }
        
        # each question has a chosen_answer that must be sent along with the question type
        count = 1
        subject.verification_questions.each do |question|
          # the type / answer key pair takes the form of 'questionXType / questionXAnswer'
          type = "question#{count}Type"
          answer = "question#{count}Answer"
          
          data_to_send[type] = question.type
          data_to_send[answer] = question.chosen_answer
          
          count += 1
        end
        
        self.data = data_to_send
      end
      
    end
    
    class ChallengeVerificationRequest < Request
      
      def initialize
        # corresponds to an IDology ExpectID Challenge API call
        self.url = 'https://web.idologylive.com/api/idliveq-challenge-answers.svc'
        
        super
      end
      
      def set_data(subject)
        data_to_send = {
          :username => self.credentials.username, 
          :password => self.credentials.password, 
          :idNumber => subject.idNumber
        }
        
        # each question has a chosen_answer that must be sent along with the question type
        count = 1
        subject.challenge_questions.each do |question|
          # the type / answer key pair takes the form of 'questionXType / questionXAnswer'
          type = "question#{count}Type"
          answer = "question#{count}Answer"
          
          data_to_send[type] = question.type
          data_to_send[answer] = question.chosen_answer
          
          count += 1
        end
        
        self.data = data_to_send
      end
      
    end
    
  end
end