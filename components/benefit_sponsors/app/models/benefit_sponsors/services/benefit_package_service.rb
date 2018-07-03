module BenefitSponsors
  module Services
    class BenefitPackageService

      attr_reader :benefit_package_factory, :benefit_application, :employer_profile, :benefit_package

      def initialize(factory_kind = BenefitSponsors::BenefitPackages::BenefitPackageFactory)
        @benefit_package_factory = factory_kind
      end

      # load defaults from models
      def load_default_form_params(form)
        application  = find_benefit_application(form)
        form.id = application.benefit_packages.new.id
        form.is_new_package = true
      end

      def load_form_metadata(form)
        application  = find_benefit_application(form)
        @employer_profile = benefit_application.benefit_sponsorship.profile
        form.catalog = BenefitSponsors::BenefitApplications::BenefitSponsorCatalogDecorator.new(application.benefit_sponsor_catalog)
      end

      def load_form_params_from_resource(form, load_benefit_application_form)
        application  = find_benefit_application(form)
        benefit_package = find_model_by_id(form.id)
        if load_benefit_application_form
          form.parent = BenefitSponsors::Forms::BenefitApplicationForm.for_edit(id: application.id.to_s, benefit_sponsorship_id: application.benefit_sponsorship.id.to_s)
        end
        form.is_new_package = false
        attributes_to_form_params(benefit_package, form)
      end

      def load_form_params_from_previous_selection(form)
        form.sponsored_benefits.each do |sb_form|
          load_form_params_from_previous_sponsored_benefit(form, sb_form) if sb_form.product_package_kind.blank?
        end
        form
      end

      def load_form_params_from_previous_sponsored_benefit(form, sb_form)
        benefit_package = find_model_by_id(form.id)
        sb = benefit_package.sponsored_benefits.where(id: sb_form.id).first
        sb_form.reference_plan_id = sb.reference_product_id
        sb_form.product_package_kind = sb.product_package_kind
        sb_form
      end

      def disable_benefit_package(form)
        benefit_application = find_benefit_application(form)
        benefit_package = find_model_by_id(form.id)
        if benefit_application.benefit_packages.size > 1
          if benefit_package.cancel_member_benefits
            return [true, benefit_package]
          else
            map_errors_for(benefit_package, onto: form)
            return [false, nil]
          end
        else
          form.errors.add(:base, "Benefit package can not be deleted because it is the only benefit package remaining in the plan year.")
          return [false, nil]
        end
      end

      def save(form)
        benefit_application = find_benefit_application(form)
        model_attributes = form_params_to_attributes(form)
        benefit_package = benefit_package_factory.call(benefit_application, model_attributes)
        store(form, benefit_package)
      end

      # No dental in MA. So, calculating premiums only for health sponsored benefits.
      def calculate_premiums(form)
        selected_package = form.catalog.product_packages.where(:package_kind => form.sponsored_benefits[0].product_package_kind).first
        lowest_cost_product = selected_package.lowest_cost_product
        highest_cost_product = selected_package.highest_cost_product
        reference_product = BenefitMarkets::Products::Product.where(id: form.sponsored_benefits[0].reference_plan_id).first

        sponsored_benefit_with_lowest_cost_product  = decorated_sponsored_benefit(lowest_cost_product, selected_package)
        sponsored_benefit_with_highest_cost_product = decorated_sponsored_benefit(highest_cost_product, selected_package)
        sponsored_benefit_with_reference_product    = decorated_sponsored_benefit(reference_product, selected_package)

        [sponsored_benefit_with_lowest_cost_product, sponsored_benefit_with_reference_product, sponsored_benefit_with_highest_cost_product]
      end

      def reference_product_details(form, details)
        product = find_product(form)
        benefit_application = find_benefit_application(form)
        hios_id = [] << product.hios_id
        year = benefit_application.start_on.year
        coverage_kind = product.kind.to_s
        qhps = Products::QhpCostShareVariance.find_qhp_cost_share_variances(hios_id.to_a, year, coverage_kind)
        if details.nil?
          visit_types = coverage_kind == "health" ? Products::Qhp::VISIT_TYPES : Products::Qhp::DENTAL_VISIT_TYPES
        else
          visit_types = qhps.first.qhp_service_visits.map(&:visit_type)
        end

        [qhps, visit_types]
      end

      def find_product(form)
        product_id = form.sponsored_benefits[0].reference_plan_id
        BenefitMarkets::Products::Product.find product_id
      end

      def decorated_sponsored_benefit(product, package)
        dummy_sponsored_benefit = create_dummy_sponsored_benefit(benefit_application)
        dummy_sponsored_benefit.reference_product = product

        cost_estimator = initialize_cost_estimator
        cost_estimator.calculate(dummy_sponsored_benefit, product, package)
      end

      # Creating dummy sponsored benefit as estimator expects one.
      def create_dummy_sponsored_benefit(benefit_application)
        benefit_package = benefit_application.benefit_packages.build
        benefit_package.sponsored_benefits.build
      end

      def initialize_cost_estimator
        BenefitSponsors::SponsoredBenefits::CensusEmployeeCoverageCostEstimator.new(benefit_application.benefit_sponsorship, benefit_application.effective_period.min)
      end

      def update(form)
        benefit_application = find_benefit_application(form)
        model_attributes = form_params_to_attributes(form)
        benefit_package  = benefit_package_factory.call(benefit_application, model_attributes)
        store(form, benefit_package)
      end

      # TODO: Test this query for benefit applications cca/dc
      # TODO: Change it back to find once find method on BenefitApplication is fixed.
      def find_model_by_id(id)
        return @benefit_package if defined? @benefit_package
        @benefit_package = @benefit_application.benefit_packages.find(id)
      end

      # TODO: Change it back to find once find method on BenefitSponsorship is fixed.
      def find_benefit_application(form)
        return @benefit_application if defined? @benefit_application
        @benefit_application = BenefitSponsors::BenefitApplications::BenefitApplication.find(form.benefit_application_id)
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
        benefit_package.sponsored_benefits.each do |sb|
          cost_estimator = BenefitSponsors::SponsoredBenefits::CensusEmployeeCoverageCostEstimator.new(benefit_application.benefit_sponsorship, benefit_application.effective_period.min)
          sbenefit, _price, _cont = cost_estimator.calculate(sb, sb.reference_product, sb.product_package)
          sbenefit.save!
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

      private

      def attributes_to_form_params(benefit_package, form)
        form.attributes = {
          title: benefit_package.title,
          description: benefit_package.description,
          probation_period_kind: benefit_package.probation_period_kind,
          probation_period_display_name: benefit_package.probation_period_display_name,
          sponsored_benefits: sponsored_benefits_attributes_to_form_params(benefit_package)
        }

        form.attributes
      end

      def sponsored_benefits_attributes_to_form_params(benefit_package)
        benefit_package.sponsored_benefits.inject([]) do |sponsored_benefits, sponsored_benefit|
          sponsored_benefits << Forms::SponsoredBenefitForm.new({
            id: sponsored_benefit.id,
            product_option_choice: sponsored_benefit.product_option_choice,
            product_package_kind: sponsored_benefit.product_package_kind,
            reference_plan_id: sponsored_benefit.reference_product.id,
            reference_product: reference_product_attributes_to_form_params(sponsored_benefit.reference_product),
            sponsor_contribution: sponsored_contribution_attributes_to_form_params(sponsored_benefit)
          })
        end
      end

      def reference_product_attributes_to_form_params(reference_product)
        Forms::Product.new({
          title: reference_product.title,
          issuer_name: reference_product.issuer_profile.legal_name,
          plan_kind: reference_product.health_plan_kind,
          metal_level_kind: reference_product.metal_level_kind
        })
      end

      def sponsored_contribution_attributes_to_form_params(sponsored_benefit)
        contribution_levels = sponsored_benefit.sponsor_contribution.contribution_levels.inject([]) do |contribution_levels, contribution_level|
          contribution_levels << Forms::ContributionLevelForm.new({
            id: contribution_level.id,
            display_name: contribution_level.display_name,
            contribution_factor: contribution_level.contribution_factor,
            is_offered: contribution_level.is_offered
          })
        end
        Forms::SponsorContributionForm.new({contribution_levels: contribution_levels})
      end

      def form_params_to_attributes(form)
        attributes = {
          id: form.id,
          title: form.title,
          description: form.description,
          probation_period_kind: form.probation_period_kind
        }
        attributes[:sponsored_benefits_attributes] = sponsored_benefits_attributes(form)
        attributes
      end

      def sponsored_benefits_attributes(form)
        form.sponsored_benefits.inject([]) do |sponsored_benefits, sponsored_benefit|
          sponsored_benefits << {
            id: sponsored_benefit.id,
            kind: sponsored_benefit.kind,
            product_package_kind: sponsored_benefit.product_package_kind,
            product_option_choice: sponsored_benefit.product_option_choice,
            reference_plan_id: sponsored_benefit.reference_plan_id,
            sponsor_contribution_attributes: sponsor_contribution_attributes(sponsored_benefit)
          }
        end
      end

      def sponsor_contribution_attributes(sponsored_benefit)
        contribution = sponsored_benefit.sponsor_contribution
        contribution_levels = contribution.contribution_levels.inject([]) do |contribution_levels, contribution_level|
          contribution_levels << {
            id: contribution_level.id,
            display_name: contribution_level.display_name,
            contribution_factor: (contribution_level.contribution_factor * 0.01),
            is_offered: contribution_level.is_offered
          }
        end

        { contribution_levels_attributes: contribution_levels}
      end
    end
  end
end
