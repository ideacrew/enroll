module Forms
  module QleForms
    class QleForm
  	  include Virtus.model
  	  extend ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Model
      include ActiveModel::Validations
      
      # TODO: Check if still needed
      # Quick workaround for params not being allowed
      attr_accessor :service, :model_name
      
      attribute :_id, String
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
      attribute :updated_at, Date
      attribute :created_at, Date

  	  # Model Attributes
  	  attribute :visibility, Symbol
  	  attribute :title, String
  	  attribute :custom_qle_questions, Array[Forms::QleForms::QuestionForm]

      def custom_qle_questions_attributes=(custom_qle_questions_params)
        self.custom_qle_questions = custom_qle_questions_params.values
      end

      def new_question
        ::Forms::QleForms::QuestionForm.new
      end

      def self.for_edit(params)
        self.new(params)
      end

      def self.for_new
        new
      end

      # TODO: A few attributes have to be added to the form,
      # such as event_kind_label
      def self.for_create(params)
        form = self.new(params)
        form.service = resolve_service(params, "create")
        form
      end

      def self.for_update(params)
        form = self.new(params)
        form.service = resolve_service(params, "update")
        form
      end
      
      # TODO: Deactivation should only allow the submission of
      # start_on/end_on. According to the Redmine ticket:
      # Gray out the choices at the top (while leaving them
      # visible/easily readable) and only allow the admin to set
      # the "SEP/QLE available in system until" date picker field.
      # Validate that the date chosen is in the future (dev choice here:
      # disable non-future option in date picker [preferred] or prompt if not)
      # and write the chosen date to the end_on field.

      def self.for_deactivation_form(params)
        deactivation_form_params = {
          start_on: params[:start_on],
          end_on: params[:end_on]
        }
        form = self.new(deactivation_form_params)
        form
      end

      def self.for_creation_form(params)
        creation_form_params = {
          start_on: params[:start_on],
          end_on: params[:end_on]
        }
        form = self.new(creation_form_params)
        form
      end

      def self.for_create(params)
        create_params = {
          start_on: params[:start_on],
          end_on: params[:end_on]
        }
        form = self.new(create_params)
        form
      end

      def self.for_deactivate(params)
        deactivate_params = {
          start_on: params[:start_on],
          end_on: params[:end_on]
        }
        form = self.new(deactivate_params)
        form.service = resolve_service(deactivate_params, "deactivate")
        form
      end

      def self.resolve_service(attrs={}, find_or_create)
        @service = ::Services::QleFormService.new(attrs, find_or_create)
      end
      
      # TODO: Possibly able to delete
      # Note: for form_for
      # https://stackoverflow.com/a/36441749/5331859
      def model_name
        QualifyingLifeEventKind.model_name
      end
    end
  end
end
