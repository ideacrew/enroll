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

      delegate :start_on, :end_on, to: :benefit_application

      # # Length of time New Hire must wait before coverage effective date
      # field :probation_period, type: Range
 

      # # The date range when this application is active
      # field :effective_period,        type: Range

      # # The date range when all members may enroll in benefit products
      # field :open_enrollment_period,  type: Range


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
        Date.today
      end

      # TODO: there can be only one sponsored benefit of each kind
      def add_sponsored_benefit(new_sponsored_benefit)
        sponsored_benefits << new_sponsored_benefit
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

      def renew_member_benefits(member_collection)
        member_collection.each do |member|
          renew_member_benefit(member)
        end
      end


      def probation_period_display_name
        probation_period_display_texts = {
          first_of_month: "First of the month following or coinciding with date of hire",
          first_of_month_after_30_days: "First of the month following 30 days",
          first_of_month_after_60_days: "First of the month following 60 days"
        }

        probation_period_display_texts[probation_period_kind]
      end

      def renew_member_benefit(census_employee)
        predecessor_benefit_package = predecessor

        employee_role = census_employee.employee_role
        family = employee_role.primary_family
        
        if family.blank?
          return [false, "family missing for #{census_employee.full_name}"]
        end

        family.validate_member_eligibility_policy 
        if family.is_valid?

          enrollments = family.enrollments.by_benefit_sponsorship(benefit_sponsorship)
          .by_effective_period(predecessor_benefit_package.effective_period)
          .enrolled_and_waived
          
          sponsored_benefits.map(&:product_kind).each do |product_kind|
            enrollment = enrollments.by_coverage_kind(product_kind).first

            if is_renewal_benefit_available?(enrollment)
              enrollment.renew_benefit(self)
            end
          end
        end
      end

      def is_renewal_benefit_available?(enrollment)
        return false if enrollment.blank? || enrollment.product.blank? || enrollment.product.renewal_product.blank?
        sponsored_benefit = sponsored_benefit_for(enrollment.coverage_kind)
        sponsored_benefit.product_package.products.include?(enrollment.product.renewal_product)
      end

      def sponsored_benefit_for(coverage_kind)
        sponsored_benefits.detect{|sponsored_benefit| sponsored_benefit.product_kind == coverage_kind}
      end

      def census_employees_assigned_on(effective_date)
        CensusEmployee.by_benefit_package_and_assignment_on(self, effective_date).non_terminated
      end

      def self.find(id)
        ::Caches::RequestScopedCache.lookup(:employer_calculation_cache_for_benefit_groups, id) do
          
          if benefit_application = BenefitSponsors::BenefitApplications::BenefitApplication.where(:"benefit_packages._id" => id).first
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

      def disable_benefit_package
        self.benefit_application.benefit_sponsorship.census_employees.each do |census_employee|
          benefit_package_assignments = census_employee.benefit_package_assignments.where(benefit_package_id: self.id)

          if benefit_package_assignments.present?
            benefit_package_assignments.each do |benefit_package_assignment|
              benefit_package_assignment.hbx_enrollments.each do |enrollment|
                enrollment.cancel_coverage! if enrollment.may_cancel_coverage?
              end
              benefit_package_assignment.update(is_active: false) unless self.benefit_application.is_renewing?
            end

            other_benefit_package = self.benefit_application.benefit_packages.detect{ |benefit_package| benefit_package.id != self.id }

            # TODO: Add methods on census employee
            if self.benefit_application.is_renewing?
              # census_employee.add_renew_benefit_group_assignment(other_benefit_package)
            else
              # census_employee.find_or_create_benefit_group_assignment([other_benefit_package])
            end
          end
        end

        self.is_active = false
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
