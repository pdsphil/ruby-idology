module API
  module Base
    
    class AccessCredentials; end
  
    class BasicAccessCredentials < AccessCredentials
      attr_accessor :username, :password
      
      def initialize(credentials)
        self.username = credentials[:username]
        self.password = credentials[:password]
      end
    end
  
    class Error < RuntimeError; end
    
    class ServiceError < Error; end
    
    class Request
      attr_accessor :url, :credentials      
    end

  end
end
