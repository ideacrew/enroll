module BenefitMarkets
  module Products
    class ProductPackageForm
      include Virtus.model
      include ActiveModel::Model
      include ActiveModel::Validations

      attribute :id, String
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

      # Create a form for the 'new' action.
      # Note that usually this method may have few parameters
      #   other than current user.
      # @param benefit_option_kind [String] the benefit option kind
      # @return [ProductPackageForm] an instance of the form populated with
      #   the backing attributes resolved by the service.
      def self.for_new(benefit_option_kind)
        service = resolve_service
        form = resolve_form_subclass(benefit_option_kind).new(
          :benefit_option_kind => benefit_option_kind
        )
        service.load_default_form_params(form)
        service.load_form_metadata(form)
        form
      end

      # Create a form for the 'create' action, populated with the provided
      #   parameters from the controller.
      # @param params [Hash] the params for :product_package from the controller
      # @return [ProductPackageForm] an instance of the form populated with
      #   the backing attributes resolved by the service.
      def self.for_create(params)
        service = resolve_service
        benefit_option_kind = params.require(:benefit_option_kind)
        form = resolve_form_subclass(benefit_option_kind).new(params)
        service.load_form_metadata(form)
        form
      end

      # Find the existing form corresponding to the given ID.
      # @param id [Object] an opaque ID from the controller parameters
      # @return [ProductPackageForm] an instance of the form populated with
      #   the backing attributes resolved by the service.
      def self.for_edit(id)
        find_for(id)
      end

      # Find the 'update' form corresponding to the given ID.
      # @param id [Object] an opaque ID from the controller parameters
      # @return [ProductPackageForm] an instance of the form populated with
      #   the backing attributes resolved by the service.
      def self.for_update(id)
        find_for(id)
      end

      # Validate and attempt to save the form.
      # This method will populate the errors.
      # @return [Boolean] the result of the attempted save
      def save
        persist
      end

      # Validate and attempt to persist updates.
      # This method will populate the errors.
      # @return [Boolean] the result of the attempted update
      def update_attributes(params)
        self.attributes = params
        persist(update: true)
      end

      # Has this form been successfully saved before?  Used mainly by form_for.
      # @return [Boolean] true if previously saved, otherwise false
      def persisted?
        !id.blank?
      end

      # Return the class of the policy which should be used by pundit.
      # @return [Class] the class of the policy to be used
      def policy_class
        BenefitMarkets::Products::ProductPackageFormPolicy
      end

      # @!visibility private
      def has_additional_attributes?
        false
      end

      protected

      def self.resolve_service
        ProductPackageService.new
      end

      def self.find_for(id)
        service = resolve_service
        params_form = self.new(id: id)
        form = service.load_form_params_from_resource(params_form)
        service.load_form_metadata(form)
        form
      end
      
      # @!visibility private
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

      def persist(update: false)
        return false unless self.valid?
        persist_result, persisted_object = update ? service.update(self) : service.save(self)
        return false unless persist_result
        @show_page_model = persisted_object
        true
      end

      def service
        @service ||= self.class.resolve_service
      end
    end
  end
end
