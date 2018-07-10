# Base class to generate EnrollApp EmployerProfile and child models from an existing PlanDesign Proposal
module SponsoredBenefits
  module BenefitApplications
    class EmployerProfileBuilder

      attr_reader :plan_design_organization,
                  :plan_design_proposal,
                  :benefit_application,
                  :employer_profile

      def initialize(plan_design_proposal, organization=nil)

        @plan_design_proposal = plan_design_proposal
        @plan_design_organization = @plan_design_proposal.plan_design_organization

        @profile = @plan_design_proposal.profile
        @benefit_application = @profile.benefit_application

        # TODO #FIXME We dont have owner_profile_id in plan design organization for new prospect employers
        # So we dont have a mapping from plan design organization to ::EmployerProfile.
        # If this is not correct, then we need to fix the below line.
        @organization = organization #|| ::EmployerProfile.find_or_create_by_plan_design_organization(@plan_design_organization)
        @organization_exists = @organization.persisted?
      end

      def quote_valid?
        validate_effective_date
      end

      def validate_effective_date
        if @organization.present?
          benefit_sponsorship = @organization.active_benefit_sponsorship
          if (benefit_sponsorship.present? && benefit_sponsorship.active_benefit_application.present?) || benefit_sponsorship.is_conversion?
            base_benefit_application = benefit_sponsorship.active_benefit_application || benefit_sponsorship.published_benefit_application

            if base_benefit_application.end_on.to_date.next_day != plan_design_proposal.effective_date
              raise "Quote effective date is invalid"
            end
          end
        end

        return true
      end

      def add_employer_profile
        add_census_members unless @organization_exists
      end

      def add_benefit_sponsors_benefit_application
        quote_benefit_application = @benefit_application.to_benefit_sponsors_benefit_application(@organization)
        if @organization.active_benefit_sponsorship.active_benefit_application.present? || @organization.active_benefit_sponsorship.is_conversion?
          enrollment_service = BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService.new(quote_benefit_application)
          status, renewed_benefit_application, results = enrollment_service.renew_application
          if status
            renewed_benefit_application
          else
            Rails.logger.error { "Unable to renew plan year for #{@organization.legal_name} due to #{results.values.to_sentence}" }
          end
        end

        @organization.active_benefit_sponsorship.census_employees.each do |census_employee|
          census_employee.save
        end
      end


      # Output the employer_profile
      def employer_profile
        validate_employer_profile

        return @employer_profile, census_employees
      end

      def census_employees

        @census_employees = []

        @census_employees = benefit_sponsor_enrollment_group

          # benefit_sponsorship_id
          # size
          # waived_count
          # classifications (family, employee_only...)
          # has_many or embeds_many?

      end

      def validate_census_employees
      end


      def validate_employer_profile
        raise "you must provide an employer Federal Tax ID number" if @plan_design_organization.fein.blank?

      end

      private

       # Build census members for new employer_profiles only
      def add_census_members
        add_benefit_group_assignment
      end


      def add_benefit_group_assignment
      end




    end
  end
end
