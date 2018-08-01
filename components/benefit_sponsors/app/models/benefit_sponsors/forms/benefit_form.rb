module BenefitSponsors
  module Forms
    class BenefitForm

      include Virtus.model
      include ActiveModel::Model

      attribute :package_id, String
      attribute :kind, String
      attribute :plan_offerings, Array[BenefitSponsors::Forms::SponsoredBenefitForm]


      def self.for_new(params)
        service = resolve_service(params)
        form_params = service.load_form_meta_data
        new(form_params)
      end

      def self.for_create(params)
      end

      def self.for_edit(params, load_benefit_application_form)
      end

      def self.for_update(params)
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

      def update
        persist(update: true)
      end

      def self.resolve_service(attrs={})
        return @service if defined? @service
        @service = BenefitSponsors::Services::SponsoredBenefitService.new(attrs)
      end

      def sponsored_benefits_attributes=(val)
      end
    end
  end
end
