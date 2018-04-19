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
      # @param current_user [Object] the current user object
      # @param benefit_option_kind [String] the benefit option kind
      # @return [ProductPackageForm] an instance of the form populated with
      #   the backing attributes resolved by the service.
      def self.for_new(current_user, benefit_option_kind)
        service = ProductPackageFormService.new
        form = resolve_form_subclass(benefit_option_kind).new(
          :benefit_option_kind => benefit_option_kind
        )
        service.load_default_form_params(form)
        service.load_form_metadata(form)
        form
      end

      # Create a form for the 'create' action, populated with the provided
      #   parameters from the controller.
      # @param current_user [Object] the current user object
      # @param params [Hash] the params for :product_package from the controller
      # @return [ProductPackageForm] an instance of the form populated with
      #   the backing attributes resolved by the service.
      def self.for_create(current_user, params)
        service = ProductPackageFormService.new
        benefit_option_kind = params.require(:benefit_option_kind)
        form = resolve_form_subclass(benefit_option_kind).new(params)
        service.load_form_metadata(form)
        form
      end

      # Find the existing form corresponding to the given ID.
      # @param current_user [Object] the current user object
      # @param id [Object] an opaque ID from the controller parameters
      # @return [ProductPackageForm] an instance of the form populated with
      #   the backing attributes resolved by the service.
      def self.for_edit(current_user, id)
        find_for(current_user, id)
      end

      # Find the 'update' form corresponding to the given ID.
      # @param current_user [Object] the current user object
      # @param id [Object] an opaque ID from the controller parameters
      # @return [ProductPackageForm] an instance of the form populated with
      #   the backing attributes resolved by the service.
      def self.for_update(current_user, id)
        find_for(current_user, id)
      end

      # @!visibility private
      def self.find_for(current_user, id)
        service = ProductPackageFormService.new
        params_form = self.new(id: id)
        form = service.load_form_params_from_resource(params_form)
        service.load_form_metadata(form)
        form
      end

      # Validate and attempt to save the form.
      # This method will populate the errors.
      # @return [Boolean] the result of the attempted save
      def save
        service = ProductPackageFormService.new
        return false unless self.valid?
        save_result, persisted_object = service.save(self)
        return false unless save_result
        @show_page_model = persisted_object
        true
      end

      # Validate and attempt to persist updates.
      # This method will populate the errors.
      # @return [Boolean] the result of the attempted update
      def update_attributes(params)
        service = ProductPackageFormService.new
        self.attributes = params
        return false unless self.valid?
        update_result, persisted_object = service.update(self)
        return false unless update_result 
        @show_page_model = persisted_object
        true
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

      # @!visibility private
      def has_additional_attributes?
        false
      end
    end
  end
end
