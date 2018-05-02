module BenefitSponsors
  module Forms
    class BenefitApplicationForm

      extend ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Validations
      include Virtus.model

      attribute :start_on, String
      attribute :end_on, String
      attribute :open_enrollment_start_on, String
      attribute :open_enrollment_end_on, String
      attribute :fte_count, Integer
      attribute :pte_count, Integer
      attribute :msp_count, Integer

      attribute :id, String
      attribute :benefit_sponsorship_id, String
      attribute :start_on_options, Hash

      validates :start_on, presence: true
      validates :end_on, presence: true
      validates :open_enrollment_start_on, presence: true
      validates :open_enrollment_end_on, presence: true

      # validates :validate_application_dates
      attr_reader :service, :show_page_model

      def service
        return @service if defined? @service
        @service = BenefitSponsors::Services::BenefitApplicationService.new
      end

      def self.for_new(benefit_sponsorship_id)
        form = self.new(:benefit_sponsorship_id => benefit_sponsorship_id)
        form.service.load_default_form_params(form)
        form.service.load_form_metadata(form)
        form
      end

      def self.for_create(params)
        form = self.new(params)
        form.service.load_form_metadata(form)
        form
      end

      def self.for_edit(id)
        form = self.new(id: id)
        form.service.load_form_params_from_resource(form)
        form.service.load_form_metadata(form)
        form
      end

      def self.for_update(id)
        form = self.new(id: id)
        form.service.load_form_params_from_resource(form)
        form.service.load_form_metadata(form)
        form
      end

      def self.fetch(id)
        form = self.new(id: id)
        form
      end

      def persisted?
        id.present?
      end

      def publish
        save_result, persisted_object = service.publish(self)
        @show_page_model = persisted_object
        return false unless save_result
        true
      end

      def force_publish
        save_result, persisted_object = service.force_publish(self)
        @show_page_model = persisted_object
        true
      end

      def revert
        save_result, persisted_object = service.revert(self)
        @show_page_model = persisted_object
        return false unless save_result
        true
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
    end
  end
end
