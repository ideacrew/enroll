module BenefitMarkets
  module Products
    class ProductPackageForm
      include Virtus.model
      include ActiveModel::Model
      include ActiveModel::Validations

      attribute :title, String
      attribute :contribution_model_id, String
      attribute :pricing_model_id, String
      attribute :benefit_catalog_id, String
      attribute :benefit_option_kind, String
      attribute :allowed_benefit_option_kinds, Array
      attribute :available_pricing_models, Array
      attribute :available_contribution_models, Array
      attribute :available_benefit_catalogs, Array

      attr_reader :show_page_model

      validates_presence_of :title, :allow_blank => false
      validates_presence_of :pricing_model_id, :allow_blank => false
      validates_presence_of :contribution_model_id, :allow_blank => false
      validates_presence_of :benefit_catalog_id, :allow_blank => false
      validates_inclusion_of :benefit_option_kind, :in => :allowed_benefit_option_kinds, :allow_blank => false

      def self.for_new(current_user, benefit_option_kind)
        service = NewProductPackageService.new
        form = resolve_form_subclass(benefit_option_kind).new(
          :benefit_option_kind => benefit_option_kind
        )
        service.populate_options(form)
        form
      end

      def self.for_create(current_user, opts)
        service = NewProductPackageService.new
        benefit_option_kind = opts.require(:benefit_option_kind)
        form = resolve_form_subclass(benefit_option_kind).new(opts)
        service.populate_options(form)
        form
      end

      def self.resolve_form_subclass(benefit_option_kind)
        name_parts = benefit_option_kind.to_s.split("_")
        product_kind = name_parts.last
        case benefit_option_kind.to_s
        when "metal_level_health", "issuer_health"
          "::BenefitMarkets::Products::#{product_kind.camelcase}Products::#{benefit_option_kind.to_s.camelcase}ProductPackageForm".constantize
        else
          self
        end
      end

      def has_additional_attributes?
        false
      end

      def save
        service = NewProductPackageService.new
        return false unless self.valid?
        save_result, persisted_object = service.save(self)
        return false unless save_result
        @show_page_model = persisted_object
        true
      end

      def policy_class
        BenefitMarkets::Products::ProductPackageFormPolicy
      end
    end
  end
end
