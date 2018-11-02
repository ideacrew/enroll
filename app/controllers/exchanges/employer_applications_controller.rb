class Exchanges::EmployerApplicationsController < ApplicationController
  include Pundit

  before_action :modify_admin_tabs?, only: [:terminate, :cancel]
  before_action :check_hbx_staff_role
  before_action :find_benefit_sponsorship

  def index
    @element_to_replace_id = params[:employers_action_id]
  end

  def terminate
    @application = @benefit_sponsorship.benefit_applications.find(params[:employer_application_id])
    end_on = Date.strptime(params[:end_on], "%m/%d/%Y")
    termination_kind = params['term_reason']
    transmit_to_carrier = (params['transmit_to_carrier'] == "true" || params['transmit_to_carrier'] == true) ? true : false
    @service = BenefitSponsors::Services::BenefitApplicationActionService.new(@application, { end_on: end_on, termination_kind: termination_kind, transmit_to_carrier: transmit_to_carrier })
    result, application, errors = @service.terminate_application
    if result
      flash[:notice] = "#{@benefit_sponsorship.organization.legal_name}'s Application terminated successfully."
    else
      flash[:error] = "#{@benefit_sponsorship.organization.legal_name}'s Application could not be terminated due to #{errors.inject(''){|memo, error| '#{memo}<li>#{error}</li>'}.html_safe}"
    end
    render :js => "window.location = #{exchanges_hbx_profiles_root_path.to_json}"
  end

  def cancel
    @application = @benefit_sponsorship.benefit_applications.find(params[:employer_application_id])
    transmit_to_carrier = (params['transmit_to_carrier'] == "true" || params['transmit_to_carrier'] == true) ? true : false
    @service = BenefitSponsors::Services::BenefitApplicationActionService.new(@application, { transmit_to_carrier: transmit_to_carrier })
    result, application, errors = @service.cancel_application
    if result
      flash[:notice] = "#{@benefit_sponsorship.organization.legal_name}'s Application canceled successfully."
    else
      flash[:error] = "#{@benefit_sponsorship.organization.legal_name}'s Application could not be canceled due to #{errors.inject(''){|memo, error| '#{memo}<li>#{error}</li>'}.html_safe}"
    end
    render :js => "window.location = #{exchanges_hbx_profiles_root_path.to_json}"
  end

  def reinstate

  end

  private

  def modify_admin_tabs?
    authorize HbxProfile, :modify_admin_tabs?
  end

  def check_hbx_staff_role
    unless current_user.has_hbx_staff_role?
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member" }
    end
  end

  def find_benefit_sponsorship
    @benefit_sponsorship = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.find(params[:employer_id])
  end
end