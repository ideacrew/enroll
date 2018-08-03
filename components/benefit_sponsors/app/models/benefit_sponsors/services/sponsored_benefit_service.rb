module BenefitSponsors
  module Services
    class SponsoredBenefitService

      attr_accessor :package, :kind, :catalog, :factory

      def initialize(attrs={})
        @package = find_benefit_package(attrs[:benefit_package_id])
        @kind = attrs[:kind]
        @catalog = @package.benefit_sponsor_catalog
        @factory = BenefitSponsors::SponsoredBenefits::SponsoredBenefitFactory
      end

      def load_form_meta_data(form)
        form.catalog = sponsor_catalog_decorator_class.new(package.benefit_sponsor_catalog)
        form
      end

      def save(form)
        model_attributes = form_params_to_attributes(form)
        sponsored_benefit = factory.call(package, model_attributes)
        store(form, sponsored_benefit)
      end

      def update(form)
      end

      def store(form, sponsored_benefit)
        valid_according_to_factory = factory.validate(sponsored_benefit)
        if valid_according_to_factory
          return true if sponsored_benefit.save && package.save
          map_errors_for(sponsored_benefit, onto: form)
          return false
        else
          map_errors_for(sponsored_benefit, onto: form)
          return [false, nil]
        end
      end

      def map_errors_for(sponsored_benefit, onto:)
        sponsored_benefit.errors.each do |att, err|
          onto.errors.add(map_model_error_attribute(att), err)
        end
      end

      def map_model_error_attribute(model_attribute_name)
        model_attribute_name
      end

      def sponsor_catalog_decorator_class
        "BenefitSponsors::BenefitApplications::BenefitSponsorHealthCatalogDecorator".gsub("Health", kind.humanize).constantize
      end

      def find_benefit_package(package_id)
        BenefitSponsors::BenefitPackages::BenefitPackage.find(package_id)
      end

      def profile
        return @profile if defined? @profile
        @profile = package.sponsor_profile
      end

      def organization
        return @organization if defined? @organization
        @organization = profile.organization
      end

      def form_params_to_attributes(form)
        # We always deal one Sponsored benefit at a time
        sb_form = form.sponsored_benefits.first
        attributes = sanitize_params(
          sb_form.attributes.slice(
            :id, :kind, :product_option_choice, :product_package_kind, :reference_plan_id
          )
        )
        attributes.merge!({
          sponsor_contribution_attributes: sponsor_contribution_form_to_params(sb_form.sponsor_contribution)
        })
      end

      def sponsor_contribution_form_to_params(form)
        {
          contribution_levels_attributes: contribution_levels_form_to_params(form.contribution_levels)
        }
      end

      def contribution_levels_form_to_params(contribution_levels)
        contribution_levels.inject([]) do |result, form|
          attributes = form.attributes.slice(:id, :display_name, :contribution_factor, :is_offered, :contribution_unit_id)
          attributes[:is_offered] = form.is_employee_cl ? true : form.is_offered
          result << sanitize_params(attributes)
          result
        end
      end

      def sanitize_params attrs
        attrs[:id].blank? ? attrs.except(:id) : attrs
      end
    end
  end
end
