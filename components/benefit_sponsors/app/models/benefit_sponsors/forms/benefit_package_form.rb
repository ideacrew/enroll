module BenefitSponsors
  module Forms
    class BenefitPackageForm

      extend ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Validations
      include Virtus.model

      attribute :title, String
      attribute :description, String
      attribute :probation_period_kind, String
      attribute :sponsored_benefits, Array[BenefitSponsors::Forms::SponsoredBenefitForm]

      # attr_accessor :benefit_application, :product_packages
      # validates :title, presence: true

      attr_reader :service

      def service
        return @service if defined? @service
        @service = BenefitSponsors::Services::BenefitPackageService.new
      end

      def self.for_new(benefit_application_id)
        form = self.new(:benefit_application_id => benefit_application_id)
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
    end
  end
end
