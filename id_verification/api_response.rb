require 'hpricot'

module API
  module IDVerification
    
    class Response
      attr_accessor :raw_response, :parsed_response, :result_key, :result_message, :id_number
      
      def initialize(raw_xml)

        # parse the raw xml
        self.raw_response = raw_xml
        self.parsed_response = Hpricot.XML(raw_xml)
        
        # determine what common results were sent back
        if ! (self.parsed_response/:error).empty?
          
          # first check for an error
          self.result_key = "error"
          self.result_message = (self.parsed_response/:error).inner_text

        elsif ! (self.parsed_response/:results).empty?
          
          # the api responded with something
          results = self.parsed_response/:results
          self.result_key = (results/:key).inner_text
          self.result_message = (results/:message).inner_text
          
          # the ID to be used in further API calls
          self.id_number = (self.parsed_response/"id-number").inner_text
          
        else
          
          # something else unexpected was returned
          self.result_key = "error"
          self.result_message = "The API returned an unexpected error."
          
        end
        
      end
    end
    
    class SearchResponse < Response
      attr_accessor :qualifiers
      
      def initialize(raw_xml)
        super
        
        self.qualifiers = {}
        
        # get any qualifiers that are present
        if ! (self.parsed_response/:qualifiers).empty?
          returned_qualifiers = (self.parsed_response/:qualifiers)/:qualifier
          
          returned_qualifiers.each do |qualifier|
            self.qualifiers[(qualifier/:key).inner_text] = (qualifier/:message).inner_text
          end
        end
      end
      
      def eligible_for_verification?
        if ! (self.parsed_response/"eligible-for-questions").empty?
          (self.result_key == "result.match") && ((self.parsed_response/"eligible-for-questions").inner_text == "true") && ! flagged_qualifier?
        else
          false
        end
      end
      
      
      private
      
      def flagged_qualifier?
        # these qualifier messages mean the subject is cannot be asked questions
        # they come from the Admin section of the IDology account, and can be changed if needed
        
        flagged = ["Subject is Deceased", "SSN unavailable", "SSN4 Does Not Match", "SSN Issued Prior to DOB", "SSN Is Invalid", "Single Address in File"]
        
        self.qualifiers.values.each do |value|
          if flagged.include?(value)
            return true
          end
        end
        
        # no flagged qualifier found
        return false
      end
      
    end

    class VerificationQuestionsResponse < Response
      attr_accessor :questions
      
      def initialize(raw_xml)
        super
        
        # :quesiton returns the array of individual questions, while :questions (plural) contains that array
        returned_questions = ((self.parsed_response/:questions)/:question)
        
        # parse the questions and answers returned
        if self.result_key == "result.match" && ! returned_questions.empty?
          
          self.questions = []
          
          returned_questions.each do |question|
            q = API::IDVerification::Question.new
            
            q.prompt = (question/:prompt).inner_text
            q.type = (question/:type).inner_text
            
            answers = question/:answer
            answers.each { |answer| q.candidate_answers << Answer.new(answer.inner_text) }
            
            self.questions << q
          end
        end
        
      end
    end
    
    class VerificationResponse < Response
      attr_accessor :idliveq_result_key, :idliveq_result_message
      
      def initialize(raw_xml)
        super
        
        # look for an error first
        if ! (self.parsed_response/"idliveq-error").empty?
          
          error = self.parsed_response/"idliveq-error"
          self.idliveq_result_key = (error/:key).inner_text
          self.idliveq_result_message = (error/:message).inner_text
          
        elsif ! (self.parsed_response/"idliveq-result").empty?
          
          # there was some sort of response
          result = self.parsed_response/"idliveq-result"
          self.idliveq_result_key = (result/:key).inner_text
          self.idliveq_result_message = (result/:message).inner_text
          
        else
          
          # an unexpected response
          self.idliveq_result_key = "error"
          self.idliveq_result_message = "The API returned an unexpected error."
          
        end
      end
      
      def verified?        
        case self.idliveq_result_key
          when "error"
            # if there are any errors, fail right away
            return false
          when "result.timeout"
            # timeouts fail right away
            return false
          when "result.questions.0.incorrect"
            # all correct passes
            return true
          when "result.questions.1.incorrect"
            # one incorrect answer passes
            return true
          when "result.questions.2.incorrect"
            # two incorrect passes, but we will challenge
            return true
          when "result.questions.3.incorrect"
            # three incorrect fails
            return false
          else
            # fail by default
            return false
        end
      end
      
      def challenge?
        # the logic for challenge questions is not relayed via the API, so we must set the logic here
        
        # do we need to ask 2 follow-up challenge questions? - only when 1/3 questions were correct
        self.idliveq_result_key == "result.questions.2.incorrect"
      end
      
    end
    
    class ChallengeQuestionsResponse < Response
      attr_accessor :questions
      
      def initialize(raw_xml)
        super
        
        # :quesiton returns the array of individual questions, while :questions (plural) contains that array
        returned_questions = ((self.parsed_response/:questions)/:question)
        
        # parse the questions and answers returned
        if self.result_key == "result.match" && ! returned_questions.empty?
          
          self.questions = []
          
          returned_questions.each do |question|
            q = API::IDVerification::Question.new
            
            q.prompt = (question/:prompt).inner_text
            q.type = (question/:type).inner_text
            
            answers = question/:answer
            answers.each { |answer| q.candidate_answers << Answer.new(answer.inner_text) }
            
            self.questions << q
          end
        end
      end
    end
    
    class ChallengeVerificationResponse < Response
      attr_accessor :idliveq_challenge_result_key, :idliveq_challenge_result_message
      
      def initialize(raw_xml)
        super
        
        # look for an error first
        if ! (self.parsed_response/"idliveq-challenge-error").empty?
          
          error = self.parsed_response/"idliveq-challenge-error"
          self.idliveq_challenge_result_key = (error/:key).inner_text
          self.idliveq_challenge_result_message = (error/:message).inner_text
          
        elsif ! (self.parsed_response/"idliveq-challenge-result").empty?
          
          # there was some sort of response
          result = self.parsed_response/"idliveq-challenge-result"
          self.idliveq_challenge_result_key = (result/:key).inner_text
          self.idliveq_challenge_result_message = (result/:message).inner_text
          
        else
          
          # an unexpected response
          self.idliveq_challenge_result_key = "error"
          self.idliveq_challenge_result_message = "The API returned an unexpected error."
          
        end
      end
      
      def verified?        
        case self.idliveq_challenge_result_key
          when "error"
            # if there are any errors, fail right away
            return false
          when "result.timeout"
            # timeouts fail right away
            return false
          when "result.challenge.0.incorrect"
            # all correct passes
            return true
          when "result.challenge.1.incorrect"
            # one incorrect answer fails
            return false
          when "result.challenge.2.incorrect"
            # two incorrect fails
            return false
          else
            # fail by default
            return false
        end
      end
      
    end
    
    class Question
      attr_accessor :prompt, :type, :candidate_answers, :chosen_answer
      
      def initialize
        self.prompt = self.type = ""
        self.candidate_answers = []
      end
    end
    
    class Answer
      attr_accessor :text
      
      def initialize(answer)
        self.text = answer
      end
    end
    
  end
end