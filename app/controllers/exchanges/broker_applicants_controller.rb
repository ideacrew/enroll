class Exchanges::BrokerApplicantsController < ApplicationController
  before_action :check_hbx_staff_role
  before_action :find_broker_applicant, only: [:edit, :update]

  def index
    @people = Person.exists(broker_role: true).broker_role_having_agency

    status_params = params.permit(:status)
    @status = status_params[:status] || 'applicant'

    # Searching applicants based on filters (applicant | certified | deceritifed | denied | all)
    @people = @people.send("broker_role_#{@status}") if @people.respond_to?("broker_role_#{@status}")
    @page_alphabets = page_alphabets(@people, "last_name")

    page_no = cur_page_no(@page_alphabets.first)
    @broker_applicants = @people.where("last_name" => /^#{page_no}/i)

    respond_to do |format|
      format.js
    end
  end

  def edit
    respond_to do |format|
      format.js
    end
  end

  def update
    broker_role = @broker_applicant.broker_role
    if params[:person] && params[:person][:broker_role_attributes] && params[:person][:broker_role_attributes][:reason]
      broker_role.update_attributes(:reason => params[:person][:broker_role_attributes][:reason])
    end
    if params['deny']
      broker_role.deny!
      flash[:notice] = "Broker applicant denied."
    elsif params['decertify']
      broker_role.decertify!
      flash[:notice] = "Broker applicant decertified."
    else
      broker_role.approve!
      Invitation.invite_broker!(broker_role)
      flash[:notice] = "Broker applicant approved successfully."
    end

    redirect_to "/exchanges/hbx_profiles"
  end

  private

  def find_broker_applicant
    @broker_applicant = Person.find(BSON::ObjectId.from_string(params[:id]))
  end

  def check_hbx_staff_role
    unless current_user.has_hbx_staff_role?
      redirect_to exchanges_hbx_profiles_root_path, :flash => { :error => "You must be an HBX staff member" }
    end
  end
end