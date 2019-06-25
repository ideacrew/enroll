module Forms
  module QleForms
    class QleForm
  	  include Virtus.model
  	  extend ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Model
      include ActiveModel::Validations

      attribute :action_kind_options, String
  	  attribute :event_kind_label, String
  	  attribute :action_kind, String
  	  attribute :effective_on_kinds, Array
  	  attribute :reason, String
  	  attribute :edi_code, String
  	  attribute :market_kind, String
  	  attribute :tool_tip, String
  	  attribute :pre_event_sep_in_days, Integer
  	  attribute :is_self_attested, Boolean
  	  attribute :date_options_available, Boolean
  	  attribute :post_event_sep_in_days, Integer
  	  attribute :ordinal_position, Integer
  	  attribute :is_active, Boolean
  	  attribute :event_on, Date
  	  attribute :coverage_effective_on, Date
  	  attribute :start_on, Date
  	  attribute :end_on, Date

  	  # Model Attributes
  	  attribute :visibility, Symbol
  	  attribute :title, String
  	  attribute :questions, Array[Forms::QleForms::QuestionForm]

      def new_question
        Forms::QleForms::QuestionForm.new
      end

      def self.for_new
        new
      end
    end
  end
end