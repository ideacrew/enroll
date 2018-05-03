module BenefitSponsors
  module Services
    class BenefitPackageService
      attr_reader :benefit_package_factory, :benefit_application

      def initialize(factory_kind = BenefitSponsors::BenefitPackages::BenefitPackageFactory)
        @benefit_package_factory = factory_kind
      end

      # load defaults from models
      def load_default_form_params(form)
      end

      def load_form_metadata(form)
        form.catalog = decorated_catalog
      end

      # def load_form_params_from_resource(form)
      #   benefit_application = find_model_by_id(form.id)
      #   attributes_to_form_params(benefit_application, form)
      # end

      # def save(form)
      #   model_attributes = form_params_to_attributes(form)
      #   benefit_sponsorship = find_benefit_sponsorship(form)
      #   benefit_application = benefit_package_factory.call(benefit_sponsorship, model_attributes) # build cca/dc application
      #   store(form, benefit_application)
      # end


      def decorated_catalog
        BenefitSponsorCatalogDecorator.new(self.benefit_sponsor_catalog)
      end
    end
  end
end