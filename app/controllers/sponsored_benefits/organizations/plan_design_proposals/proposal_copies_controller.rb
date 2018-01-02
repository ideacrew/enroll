module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::ProposalCopiesController < ApplicationController

      def create
        new_plan_design_proposal = SponsoredBenefits::Forms::PlanDesignProposal.new({ organization: plan_design_organization }.merge(plan_design_form.to_h))
        existing_roster = SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee.find_by_benefit_sponsor(plan_design_form.proposal.profile.benefit_sponsorships.first)

        if new_plan_design_proposal.save
          assign_roster_employees(sponsorship: new_plan_design_proposal.proposal.profile.benefit_sponsorships.first, roster: existing_roster)
          flash[:success] = "Proposal successfully copied"
        else
          flash[:error] = "Something went wrong"
        end
          redirect_to edit_organizations_plan_design_organization_plan_design_proposal_path(plan_design_organization, new_plan_design_proposal) 
        end
      end

      private
      helper_method :plan_design_form, :plan_design_organization, :plan_design_proposal

      def assign_roster_employees(sponsorship:, roster:)
        roster.each do |employee|
          census_employee = SponsoredBenefits::CensusMembers::PlanDesignCensusEmployee.new.tap do |ce|
            ce.first_name = employee.first_name
            ce.last_name = employee.last_name
            ce.gender = employee.gender
            ce.ssn = employee.ssn
            ce.dob = employee.dob
            employee.census_dependents.each do |dependent|
              new_dependent = SponsoredBenefits::CensusMembers::CensusDependent.new.tap do |dep|
                dep.first_name = dependent.first_name
                dep.last_name = dependent.last_name
                dep.gender = dependent.gender
                dep.employee_relationship = dependent.employee_relationship
                dep.dob = dependent.dob
              end
              ce.census_dependents << new_dependent
            end
            ce.address = employee.address
            ce.email = employee.email
            ce.benefit_sponsorship_id = sponsorship.id
          end
          census_employee.save!
        end
      end

      def plan_design_proposal
        @plan_design_proposal ||= SponsoredBenefits::Organizations::PlanDesignProposal.find(params[:plan_design_proposal_id])
      end

      def plan_design_organization
        @plan_design_organization ||= plan_design_proposal.plan_design_organization
      end

      def plan_design_form
        SponsoredBenefits::Forms::PlanDesignProposal.new(organization: plan_design_organization, proposal_id: params[:plan_design_proposal_id])
      end
    end
  end
end
