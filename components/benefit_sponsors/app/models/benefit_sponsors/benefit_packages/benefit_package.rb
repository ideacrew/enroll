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

      # Deprecated: replaced by FEHB profile and FEHB market
      # field :is_congress, type: Boolean, default: false

      embeds_many :sponsored_benefits,
                  class_name: "BenefitSponsors::SponsoredBenefits::SponsoredBenefit"

      delegate :benefit_sponsor_catalog, to: :benefit_application

      delegate :rate_schedule_date, to: :benefit_application

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

      def renew(new_benefit_package)
        new_benefit_package.assign_attributes({
          title: title,
          description: description,
          probation_period_kind: probation_period_kind,
          is_default: is_default
        })
        
        sponsored_benefits.each do |sponsored_benefit| 
          new_benefit_package.add_sponsored_benefit(sponsored_benefit.renew(new_benefit_package))
        end

        new_benefit_package
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
