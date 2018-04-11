module BenefitMarkets
  module Products
    class ProductPackageForm
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :title
      attr_accessor :contribution_model_id
      attr_accessor :pricing_model_id
      attr_accessor :benefit_catalog_id
      attr_accessor :benefit_option_kind
      
      attr_accessor :form_mapping

      attr_reader :show_page_model

      validates_presence_of :title, :allow_blank => false
      validates_presence_of :pricing_model_id, :allow_blank => false
      validates_presence_of :contribution_model_id, :allow_blank => false
      validates_presence_of :benefit_catalog_id, :allow_blank => false
      validates_inclusion_of :benefit_option_kind, :in => :allowed_benefit_option_kinds, :allow_blank => false

      def allowed_benefit_option_kinds
        form_mapping.benefit_option_kinds
      end

      def self.for_new(current_user, benefit_option_kind)
        resolve_form_subclass(benefit_option_kind).new(
          :benefit_option_kind => benefit_option_kind,
          :form_mapping => ::BenefitMarkets::Products::ProductPackageFormMapping.new
        )
      end

      def self.for_create(current_user, opts)
        benefit_option_kind = opts.require(:benefit_option_kind)
        resolve_form_subclass(benefit_option_kind).new(
          opts.merge({
            :form_mapping => ::BenefitMarkets::Products::ProductPackageFormMapping.new
          })
        )
      end

      def self.resolve_form_subclass(benefit_option_kind)
        name_parts = benefit_option_kind.to_s.split("_")
        product_kind = name_parts.last
        "::BenefitMarkets::Products::#{product_kind.camelcase}Products::#{benefit_option_kind.to_s.camelcase}ProductPackageForm".constantize
      end

      def available_pricing_models
        form_mapping.options_for_pricing_model_id(self)
      end

      def available_benefit_catalogs
        form_mapping.options_for_benefit_catalog_id
      end

      def available_contribution_models
        form_mapping.options_for_contribution_model_id
      end

      def has_additional_attributes?
        false
      end

      def save
        return false unless self.valid?
        save_result, persisted_object = form_mapping.save(self)
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
