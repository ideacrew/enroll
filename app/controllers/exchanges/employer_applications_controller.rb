class Exchanges::EmployerApplicationsController < ApplicationController

  before_action :check_hbx_staff_role
  before_action :find_employer

  def index
    @element_to_replace_id = params[:employers_action_id]
  end

  def edit
    @application = @employer_profile.plan_years.find(params[:id])
  end

  def terminate
    @application = @employer_profile.plan_years.find(params[:employer_application_id])
    begin
      if @application.present?
        end_on = Date.strptime(params[:end_on], "%m/%d/%Y")
        if end_on >= TimeKeeper.date_of_record
          @application.schedule_termination!(end_on) if @application.may_schedule_termination?
        else
          @application.terminate!(end_on) if @application.may_terminate?
          if @application.terminated?
            @application.update_attributes!(end_on: end_on, terminated_on: TimeKeeper.date_of_record, termination_kind: params['term_reason'])
            @application.terminate_employee_enrollments(end_on)
            @employer_profile.benefit_terminated!
          else
            flash[:error] = "Employer Application can't be terminated."
          end
        end
        flash[:notice] = "Employer Application terminated successfully."
      else
        flash[:error] = "Employer Application can't be terminated."
      end
    rescue Exception => e
      flash[:error] = "Couldn't terminate plan year due to #{e}"
    end
    render :js => "window.location = #{exchanges_hbx_profiles_root_path.to_json}"
  end

  def cancel
    @application = @employer_profile.plan_years.find(params[:employer_application_id])
    begin
      if @application.present?
        if @application.may_cancel?
          @application.cancel!
        elsif @application.may_cancel_renewal?
          @application.cancel_renewal!
        end
        @employer_profile.revert_application! if @employer_profile.may_revert_application?
        flash[:notice] = "Employer Application canceled successfully."
      else
        flash[:error] = "Employer Application can't be canceled."
      end
    rescue Exception => e
      flash[:error] = "Couldn't cancel plan year due to #{e}"
    end
    render :js => "window.location = #{exchanges_hbx_profiles_root_path.to_json}"
  end

  def reinstate
  end

  private

  def check_hbx_staff_role
    unless current_user.has_hbx_staff_role?
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member" }
    end
  end

  def find_employer
    @employer_profile = EmployerProfile.find(params[:employer_id])
  end
end