module SponsoredBenefits
  class Organizations::PlanDesignProposalsController < ApplicationController
    include Config::BrokerAgencyHelper
    include DataTablesAdapter

    before_action :load_plan_design_organization, except: [:destroy, :publish, :claim]
    before_action :load_plan_design_proposal, only: [:edit, :update, :destroy, :publish, :view_published]

    def index
      @datatable = effective_datatable
    end

    def claim
      # TODO FIXME: update routes.rb to send the plan_design_proposal_id parameter as employer_profile_id.
      employer_profile_id = params.fetch(:plan_design_proposal_id, nil)

      quote_claim_code = params.fetch(:claim_code, nil).try(:upcase)

      claim_code_status, quote = SponsoredBenefits::Organizations::PlanDesignProposal.claim_code_status?(quote_claim_code)

      # replicating the code as in dc enroll
      if claim_code_status == "invalid"
        flash[:error] = "No quote matching this code could be found. Please contact your broker representative."
      elsif claim_code_status == "claimed"
        flash[:error] = "Quote claim code already claimed."
      else
        if SponsoredBenefits::Organizations::PlanDesignProposal.build_plan_year_from_quote(employer_profile_id, quote)
          flash[:notice] = "Code claimed with success. Your Plan Year has been created."
        else
          flash[:error] = "There was an issue claiming this quote."
        end
      end

      redirect_to main_app.employers_employer_profile_path(id: employer_profile_id , tab: "benefits")
    end

    def publish
      if @plan_design_proposal.may_publish?
        @plan_design_proposal.publish!
        flash[:notice] = "Quote Published"
      else
        flash[:error] = "Quote failed to publish.".html_safe
      end
      redirect_to organizations_plan_design_organization_plan_design_proposals_path(@plan_design_proposal.plan_design_organization)
    end

    def new
      if @plan_design_organization.employer_profile.present?
        begin
          plan_design_proposal = @plan_design_organization.build_proposal_from_existing_employer_profile
          flash[:success] = "Imported quote and employee information from your client #{@plan_design_organization.employer_profile.legal_name}."
          redirect_to action: :edit, id: plan_design_proposal.id
        rescue Exception => e
          flash[:error] = e.to_s
          @plan_design_proposal = SponsoredBenefits::Forms::PlanDesignProposal.new(organization: @plan_design_organization)
          init_employee_datatable
        end
      else
        @plan_design_proposal = SponsoredBenefits::Forms::PlanDesignProposal.new(organization: @plan_design_organization)
        init_employee_datatable
      end
    end

    def show
      # load relevant quote (not nested)
      # plan_design_proposal
    end

    def view_published
      sponsorship = @plan_design_proposal.profile.benefit_sponsorships.first
      @census_employees = sponsorship.census_employees
      benefit_group = sponsorship.benefit_applications.first.benefit_groups.first
      @plan = Plan.find(benefit_group.reference_plan_id)
      @employer_contribution_amount = benefit_group.monthly_employer_contribution_amount(@plan)
    end

    def edit
      @plan_design_proposal = SponsoredBenefits::Forms::PlanDesignProposal.new(organization: @plan_design_organization, proposal_id: params[:id])
      init_employee_datatable
    end

    def create
      @plan_design_proposal = SponsoredBenefits::Forms::PlanDesignProposal.new({
          organization: @plan_design_organization
        }.merge(plan_design_proposal_params))
      
      respond_to do |format|
        if @plan_design_proposal.save
          flash[:success] = "Quote information saved successfully."
        else
          flash[:error] = "Quote information save failed."
        end

        format.js
      end
    end

    def update
      @plan_design_proposal = SponsoredBenefits::Forms::PlanDesignProposal.new({
        organization: @plan_design_organization, proposal_id: params[:id]
        }.merge(plan_design_proposal_params))

      respond_to do |format|
        if @plan_design_proposal.save
          flash[:success] = "Quote information updated successfully."
        else
          flash[:error] = "Quote information update failed."
        end

        format.js
      end
    end

    def destroy
      @plan_design_proposal.destroy!
      redirect_to organizations_plan_design_organization_plan_design_proposals_path(@plan_design_proposal.plan_design_organization._id)
    end

    private

    def effective_datatable
      ::Effective::Datatables::PlanDesignProposalsDatatable.new(organization_id: @plan_design_organization._id)
    end

    def load_plan_design_organization
      @plan_design_organization = SponsoredBenefits::Organizations::PlanDesignOrganization.find(params[:plan_design_organization_id])
      broker_agency_profile
    end

    def broker_agency_profile
      @broker_agency_profile = @plan_design_organization.broker_agency_profile
    end

    def load_plan_design_proposal
      proposal_id = params[:id] || params[:plan_design_proposal_id]
      @plan_design_proposal ||= Organizations::PlanDesignProposal.find(proposal_id)
    end

    def plan_design_proposal_params
      params.require(:forms_plan_design_proposal).permit(
        :title,
        :effective_date,
        profile: [
          benefit_sponsorship: [
            :initial_enrollment_period,
            :annual_enrollment_period_begin_month_of_year,
            benefit_application: [
              :effective_period,
              :open_enrollment_period,
            ]
          ]
        ]
        )
    end

    def init_employee_datatable
      sponsorship = @plan_design_proposal.profile.benefit_sponsorships.first
      @census_employees = sponsorship.census_employees
      @datatable = Effective::Datatables::PlanDesignEmployeeDatatable.new({id: sponsorship.id, scopes: params[:scopes]})
    end
  end
end
