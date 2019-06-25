module Forms
  module QleForms
    class AnswerForm
      include Virtus.model
  	  extend ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Model
      include ActiveModel::Validations

      attribute :responses, Array[Forms::QleForms::ResponseForm]

      def new_response
        Forms::QleForms::ResponseForm.new
      end
    end
  end
end
