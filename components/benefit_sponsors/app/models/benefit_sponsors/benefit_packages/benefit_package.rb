module BenefitSponsors
  module BenefitPackages
    class BenefitPackage
      include Mongoid::Document
      include Mongoid::Timestamps


      embedded_in :benefit_application, class_name: "BenefitSponsors::BenefitApplications::BenefitApplication"

      field :title, type: String, default: ""
      field :description, type: String, default: ""
      field :probation_period_kind, type: Symbol
      field :is_default, type: Boolean, default: false
      field :is_active, type: Boolean, default: true
      field :predecessor_id, type: BSON::ObjectId

      # Deprecated: replaced by FEHB profile and FEHB market
      # field :is_congress, type: Boolean, default: false

      embeds_many :sponsored_benefits,
                  class_name: "BenefitSponsors::SponsoredBenefits::SponsoredBenefit",
                  cascade_callbacks: true, validate: true

      accepts_nested_attributes_for :sponsored_benefits

      delegate :benefit_sponsor_catalog, to: :benefit_application
      delegate :rate_schedule_date,      to: :benefit_application
      delegate :effective_period,        to: :benefit_application
      delegate :predecessor_application, to: :benefit_application

      delegate :start_on, :end_on, :open_enrollment_period, to: :benefit_application
      delegate :open_enrollment_start_on, :open_enrollment_end_on, to: :benefit_application
      delegate :recorded_rating_area, to: :benefit_application
      delegate :benefit_sponsorship, to: :benefit_application
      delegate :recorded_service_area_ids, to: :benefit_application
      delegate :benefit_market, to: :benefit_application

      validates_presence_of :title, :probation_period_kind, :is_default, :is_active, :sponsored_benefits

      # calculate effective on date based on probation period kind
      # Logic to deal with hired_on and created_at
      # returns a roster
      def new_hire_effective_on(roster)
      end

      def eligible_on(date_of_hire)
        # TODO
        Date.today
      end

      def effective_on_for(date_of_hire)
        # TODO
        shopping_date = ::TimeKeeper.date_of_record
        if open_enrollment_period.include?(shopping_date)
          start_on
        else
          ::TimeKeeper.date_of_record
        end
      end

      def open_enrollment_contains?(date)
        open_enrollment_period.include?(date)
      end

      def package_for_open_enrollment(shopping_date)
        if open_enrollment_period.include?(shopping_date)
          return self
        elsif (shopping_date < open_enrollment_start_on)
          return nil unless predecessor.present?
          predecessor.package_for_open_enrollment(shopping_date)
        else
          return nil unless successor.present?
          successor.package_for_open_enrollment(shopping_date)
        end
      end

      def package_for_date(coverage_start_date)
        if (coverage_start_date <= end_on) && (coverage_start_date >= start_on)
          return self
        elsif (coverage_start_date < start_on)
          return nil unless predecessor.present?
          predecessor.package_for_date(coverage_start_date)
        else
          return nil unless successor.present?
          successor.package_for_date(coverage_start_date)
        end
      end

      # TODO: there can be only one sponsored benefit of each kind
      def add_sponsored_benefit(new_sponsored_benefit)
        sponsored_benefits << new_sponsored_benefit
      end

      def health_sponsored_benefit
        sponsored_benefits.where(_type: /.*HealthSponsoredBenefit/).first
      end

      def dental_sponsored_benefit
        sponsored_benefits.where(_type: /.*DentalSponsoredBenefit/).first
      end

      def rating_area
        recorded_rating_area.blank? ? benefit_group.benefit_sponsorship.rating_area : recorded_rating_area
      end
      
      def drop_sponsored_benefit(sponsored_benefit)
        sponsored_benefits.delete(sponsored_benefit)
      end

      def predecessor
        return @predecessor if defined? @predecessor
        @predecessor = predecessor_application.benefit_packages.find(self.predecessor_id)
      end

      def predecessor=(old_benefit_package)
        raise ArgumentError.new("expected BenefitPackage") unless old_benefit_package.is_a? BenefitSponsors::BenefitPackages::BenefitPackage
        self.predecessor_id = old_benefit_package._id
        @predecessor = old_benefit_package
      end

      def probation_period_display_name
        probation_period_display_texts = {
          first_of_month: "First of the month following or coinciding with date of hire",
          first_of_month_after_30_days: "First of the month following 30 days",
          first_of_month_after_60_days: "First of the month following 60 days"
        }

        probation_period_display_texts[probation_period_kind]
      end

      def renew(new_benefit_package)
        new_benefit_package.assign_attributes({
          title: title,
          description: description,
          probation_period_kind: probation_period_kind,
          is_default: is_default
        })

        new_benefit_package.predecessor = self

        sponsored_benefits.each do |sponsored_benefit|
          new_benefit_package.add_sponsored_benefit(sponsored_benefit.renew(new_benefit_package))
        end

        new_benefit_package
      end

      def renew_employee_assignments
        assigned_census_employees = predecessor_benefit_package.census_employees_assigned_on(predecessor.effective_period.min)

        assigned_census_employees.each do |census_employee|
          new_benefit_package_assignment = census_employee.benefit_package_assignment_on(effective_period.min)

          if new_benefit_package_assignment.blank?
            census_employee.assign_to_benefit_package(self, effective_period.min)
          end
        end
      end

      def renew_member_benefits
        census_employees_assigned_on(effective_period.min).each { |member| renew_member_benefit(member) }
      end

      def renew_member_benefit(census_employee)
        predecessor_benefit_package = predecessor

        employee_role = census_employee.employee_role
        family = employee_role.primary_family

        return [false, "family missing for #{census_employee.full_name}"] if family.blank?

        family.validate_member_eligibility_policy
        if family.is_valid?

          enrollments = family.enrollments.by_benefit_sponsorship(benefit_sponsorship)
          .by_effective_period(predecessor_benefit_package.effective_period)
          .enrolled_and_waived

          sponsored_benefits.map(&:product_kind).each do |product_kind|
            hbx_enrollment = enrollments.by_coverage_kind(product_kind).first

            if hbx_enrollment && is_renewal_benefit_available?(hbx_enrollment)
              hbx_enrollment.renew_benefit(self)
            end
          end
        end
      end

      def is_renewal_benefit_available?(enrollment)
        return false if enrollment.blank? || enrollment.product.blank? || enrollment.product.renewal_product.blank?
        sponsored_benefit = sponsored_benefit_for(enrollment.coverage_kind)
        sponsored_benefit.product_package.products.include?(enrollment.product.renewal_product)
      end

      def effectuate_family_coverages(family)
        enrollments = family.enrollments.by_benefit_package(self).enrolled_and_waived
        sponsored_benefits.map(&:product_kind).each do |product_kind|
          hbx_enrollment = enrollments.by_coverage_kind(product_kind).first
          hbx_enrollment.begin_coverage! if hbx_enrollment && hbx_enrollment.may_begin_coverage?
        end
      end

      def expire_family_coverages(family)
        enrollments = family.enrollments.by_benefit_package(self).enrolled_and_waived
        sponsored_benefits.map(&:product_kind).each do |product_kind|
          hbx_enrollment = enrollments.by_coverage_kind(product_kind).first
          hbx_enrollment.expire_coverage! if hbx_enrollment && hbx_enrollment.may_expire_coverage?
        end
      end

      def terminate_family_coverages(family)
        enrollments = family.enrollments.by_benefit_package(self).enrolled_and_waived
        sponsored_benefits.map(&:product_kind).each do |product_kind|
          hbx_enrollment = enrollments.by_coverage_kind(product_kind).first
          if hbx_enrollment && hbx_enrollment.may_terminate_coverage?
            hbx_enrollment.terminate_coverage!
            hbx_enrollment.update_attributes!(terminated_on: benefit_application.end_on, termination_submitted_on: benefit_application.terminated_on)
          end
        end
      end

      def cancel_family_coverages(family)
        enrollments = family.enrollments.by_benefit_package(self).enrolled_and_waived
        sponsored_benefits.map(&:product_kind).each do |product_kind|
          hbx_enrollment = enrollments.by_coverage_kind(product_kind).first
          hbx_enrollment.cancel_coverage! if hbx_enrollment && hbx_enrollment.may_cancel_coverage?
        end
      end

      def deactivate
        self.update_attributes(is_active: false)
      end

      def sponsored_benefit_for(coverage_kind)
        # I know it's a symbol - but we should behave like indifferent access here
        sponsored_benefits.detect{|sponsored_benefit| sponsored_benefit.product_kind.to_s == coverage_kind.to_s }
      end

      def census_employees_assigned_on(effective_date)
        CensusEmployee.by_benefit_package_and_assignment_on(self, effective_date).non_terminated
      end

      def self.find(id)
        ::Caches::RequestScopedCache.lookup(:employer_calculation_cache_for_benefit_groups, id) do

          if benefit_application = BenefitSponsors::BenefitApplications::BenefitApplication.where(:"benefit_packages._id" => BSON::ObjectId.from_string(id)).first
            benefit_application.benefit_packages.find(id)
          else
            nil
          end
        end
      end

      # Scenario 1: sponsored_benefit is missing (because product not available during renewal)
      def refresh

      end

      #  Scenario 2: sponsored_benefit is present
      def refresh!(new_benefit_sponsor_catalog)
        # construct sponsored benefits again
        # compare them with old ones

        sponsored_benefits.each do |sponsored_benefit|
          current_product_package = sponsored_benefit.product_package
          new_product_package = new_benefit_sponsor_catalog.product_package_for(sponsored_benefit)

          if current_product_package != new_product_package
            sponsored_benefit.refresh
          end
        end
      end

      def build_relationship_benefits
      end

      def build_dental_relationship_benefits
      end

      def self.transform_to_sponsored_benefit_template(product_package)
        sponsored_benefit = TransformProductPackageToSponsoredBenefit.new(product_package).transform
      end

      def set_sponsor_choices(sponsored_benefit)
        # trigger composite

      end

      def sponsored_benefits=(sponsored_benefits_attrs)
        sponsored_benefits_attrs.each do |sponsored_benefit_attrs|
          sponsored_benefit = sponsored_benefits.build
          sponsored_benefit.assign_attributes(sponsored_benefit_attrs)
        end
      end

      # Deprecate below methods in future

      def plan_year
        warn "[Deprecated] Instead use benefit_application" unless Rails.env.test?
        benefit_application
      end
    end
  end
end
