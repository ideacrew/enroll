module Forms
  module QleForms
    class QuestionForm
  	  include Virtus.model
  	  extend ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Model
      include ActiveModel::Validations

      attribute :content, String
      attribute :type, String
      attribute :answer, Forms::QleForms::AnswerForm

      def answer_attributes=(answer_params)
        self.answer = answer_params
      end

      def new_answer
        Forms::QleForms::AnswerForm.new
      end
    end
  end
end
