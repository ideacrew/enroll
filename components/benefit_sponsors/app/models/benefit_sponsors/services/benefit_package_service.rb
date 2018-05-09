module BenefitSponsors
  module Services
    class BenefitPackageService

      attr_reader :benefit_package_factory, :benefit_application

      def initialize(factory_kind = BenefitSponsors::BenefitPackages::BenefitPackageFactory)
        @benefit_package_factory = factory_kind
      end

      # load defaults from models
      def load_default_form_params(form)
        application  = find_benefit_application(form)
        form.id = application.benefit_packages.new.id
      end

      def load_form_metadata(form)
        application  = find_benefit_application(form)
        form.catalog = BenefitSponsors::BenefitApplications::BenefitSponsorCatalogDecorator.new(application.benefit_sponsor_catalog)
      end

      def load_form_params_from_resource(form)
        benefit_package = find_model_by_id(form.id)
        attributes_to_form_params(benefit_package, form)
      end

      def save(form)
        model_attributes = form_params_to_attributes(form)
        benefit_application = find_benefit_application(form)
        benefit_package = benefit_package_factory.call(benefit_application, model_attributes)
        store(form, benefit_package)
      end

      def update(form)
        benefit_package = find_model_by_id(form.id)
        model_attributes = form_params_to_attributes(form)
        benefit_package.assign_attributes(model_attributes)
        store(form, benefit_package)
      end

      # TODO: Test this query for benefit applications cca/dc
      # TODO: Change it back to find once find method on BenefitApplication is fixed.
      def find_model_by_id(id)
        BenefitSponsors::BenefitPackages::BenefitPackage.where(id: id).first
      end

      # TODO: Change it back to find once find method on BenefitSponsorship is fixed.
      def find_benefit_application(form)
        return @benefit_application if defined? @benefit_application
        @benefit_application = BenefitSponsors::BenefitApplications::BenefitApplication.where(id: form.benefit_application_id).first
      end

      def attributes_to_form_params(benefit_package, form)
        form.attributes = {
          title: benefit_package.title,
          description: benefit_package.description,
          probation_period_kind: benefit_package.probation_period_kind
        }
      end

      def form_params_to_attributes(form)
        {
          title: form.title,
          description: form.description,
          probation_period_kind: form.probation_period_kind,
        }
      end

      def store(form, benefit_package)
        valid_according_to_factory = benefit_package_factory.validate(benefit_application)
        if valid_according_to_factory
        else
          map_errors_for(benefit_package, onto: form)
          return [false, nil]
        end
        save_successful = benefit_package.save
        unless save_successful
          map_errors_for(benefit_package, onto: form)
          return [false, nil]
        end
        [true, benefit_package]
      end

      def map_errors_for(benefit_package, onto:)
        benefit_package.errors.each do |att, err|
          onto.errors.add(map_model_error_attribute(att), err)
        end
      end

      # We can cheat here because our form and our model are so
      # close together - normally this will be more complex
      def map_model_error_attribute(model_attribute_name)
        model_attribute_name
      end
    end
  end
end