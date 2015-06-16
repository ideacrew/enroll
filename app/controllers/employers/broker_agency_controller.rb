class Employers::BrokerAgencyController < ApplicationController

  before_action :find_employer
  before_action :find_borker_agency

  #TODO move assign_broker_agency to here
  def create
  end

  def terminate
    termination_date = params["termination_date"]
    if termination_date.present?
      termination_date = DateTime.strptime(termination_date, '%m/%d/%Y').try(:to_date)
    else
      termination_date = ""
    end

    last_day_of_work = termination_date
    if termination_date.present?
      @employer_profile.terminate_active_broker_agency(last_day_of_work)
      @fa = @employer_profile.save!
    end

    respond_to do |format|
      format.js {
        if termination_date.present? and @fa
          flash[:notice] = "Successfully terminated broker agency."
          render text: true
        else
          render text: false
        end
      }
      format.all {
        flash[:notice] = "Successfully terminated broker agency."
        redirect_to employers_employer_profile_path(@employer_profile)
      }
    end
  end

  private

  def find_employer
    @employer_profile = EmployerProfile.find(params["employer_profile_id"])
  end

  def find_borker_agency
    id = params[:id] || params[:broker_agency_id]
    @broker_agency = BrokerAgencyProfile.find(id)
  end
end