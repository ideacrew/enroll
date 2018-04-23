module BenefitSponsors
  module Forms
    class BenefitApplicationForm

      extend ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Validations
      include Virtus.model

      attribute :start_on, Date
      attribute :end_on, Date
      attribute :open_enrollment_start_on, Date
      attribute :open_enrollment_end_on, Date
      attribute :fte_count, Integer
      attribute :pte_count, Integer
      attribute :msp_count, Integer

      attribute :id, String
      attribute :benefit_sponsorship_id, String
      attribute :start_on_options, Array


      validates :start_on, presence: true
      validates :end_on, presence: true
      validates :open_enrollment_start_on, presence: true
      validates :open_enrollment_end_on, presence: true

      # validates :validate_application_dates
      attr_reader :service

      def service
        return @service if defined? @service
        @service = BenefitSponsors::Services::BenefitApplicationService.new
      end

      def self.for_new(benefit_sponsorship_id)
        form = self.new(:benefit_sponsorship_id => benefit_sponsorship_id)
        service.load_default_form_params(form)
        service.load_form_metadata(form)
        form
      end

      def self.for_create(params)
        form = self.new(params)
        service.load_form_metadata(form)
        form
      end

      def self.for_edit(id)
        form = self.new(id: id)
        service.load_form_params_from_resource(form)
        service.load_form_metadata(form)
        form
      end

      def self.for_update(id)
        form = self.new(id: id)
        service.load_form_params_from_resource(form)
        service.load_form_metadata(form)
        form
      end

      def persisted?
        id.present?
      end

      def persist(update: false)
        return false unless self.valid?
        save_result, persisted_object = (update ? service.update(self) : service.save(self))
        return false unless save_result
        @show_page_model = persisted_object
        true
      end

      def save
        persist
      end

      def update_attributes(params)
        self.attributes = params
        persist(update: true)
      end

      def validate_application_dates
        if start_on <= end_on
          errors.add(:start_on, "can't be later than end on date")
        end
      end

      private 

      def persist!
        @benefit_application_service.store!(self)
      end
    end
  end
end
