module IdentityVerification
  class InteractiveVerification
    class Response
      extend ActiveModel::Naming
      include ActiveModel::Model
      attr_accessor :response_text, :response_id
    end

    class Question
      extend ActiveModel::Naming
      include ActiveModel::Model
      include ActiveModel::Validations
      attr_accessor :question_id, :question_text
      attr_accessor :response_id

      attr_writer :responses

      validates_presence_of :response_id, :message => "You must select a response."

      def unanswered?
        @response_id.blank?
      end

      def responses
        @responses ||= []
      end
      def response_attributes=(vals)
        @responses = vals.map do |v|
          ::IdentityVerification::InteractiveVerification::Response.new(v)
        end
      end

      def response_attributes 
        @responses.map do |q|
          q.attributes
        end
      end
    end

    extend ActiveModel::Naming
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :questions, :session_id, :transaction_id

    validate :questions_have_responses

    def questions_have_responses
      if questions.any?(:unanswered?)
        errors.add(:base, "You must answer all questions")
      end
    end

    def questions
      @questions ||= []
    end

    def questions_attributes=(vals)
      @questions = vals.map do |v|
        ::IdentityVerification::InteractiveVerification::Question.new(v)
      end
    end

    def questions_attributes
      @questions.map do |q|
        q.attributes
      end
    end
  end
end
