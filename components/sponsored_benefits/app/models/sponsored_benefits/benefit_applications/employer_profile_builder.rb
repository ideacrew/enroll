# Base class to generate EnrollApp EmployerProfile and child models from an existing PlanDesign Proposal
module SponsoredBenefits
  module BenefitApplications
    class EmployerProfileBuilder

      attr_reader :plan_design_organization,
                  :plan_design_proposal,
                  :benefit_application,
                  :employer_profile


      def initialize(plan_design_proposal, employer_profile=nil)

        @plan_design_proposal = plan_design_proposal
        @plan_design_organization = @plan_design_proposal.plan_design_organization

        @profile = @plan_design_proposal.profile
        @benefit_application = @profile.benefit_application

        # TODO #FIXME We dont have owner_profile_id in plan design organization for new prospect employers
        # So we dont have a mapping from plan design organization to ::EmployerProfile.
        # If this is not correct, then we need to fix the below line.
        @employer_profile = employer_profile || ::EmployerProfile.find_or_create_by_plan_design_organization(@plan_design_organization)
        @employer_profile_exists = @employer_profile.persisted?
      end

      def add_employer_profile
        add_census_members unless @employer_profile_exists
      end

      def add_plan_year
        @employer_profile.plan_years << @benefit_application.to_plan_year
        @employer_profile.save
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
