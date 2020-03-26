class Api::V1::AgenciesController < Api::V1::ApiBaseController

  before_action :authenticate_user!

  def index
    query = Queries::AgenciesQuery.new
    authorize query, :list_agencies?
    render json: query.to_json(
             :only => [:dba, :legal_name],
             :methods => [:agency_profile_id, :organization_id, :agency_profile_type]
           )
  end

  def agency_staff
    query = Queries::People::NonPrimaryAgentsQuery.new
    authorize query, :list_agency_staff?
    render json: query.to_json(
      :only => [:_id, :first_name, :last_name, :hbx_id],
      :methods => [:agency_roles]
    )
  end

  def primary_agency_staff
    query = Queries::People::PrimaryAgentsQuery.new
    authorize query, :list_primary_agency_staff?
    render json: query.to_json(
      :only => [:first_name, :last_name, :hbx_id],
      :methods => [:agent_npn, :agent_role_id, :connected_profile_id]
    )
  end

  def agency_staff_detail
    query = Queries::People::AgencyStaffDetailQuery.new(params[:person_id])
    authorize query, :view_agency_staff_details?
    render json: query.person.to_json(
      :only => [:_id, :first_name, :last_name, :hbx_id, :dob],
      :methods => [:agency_roles, :agent_emails]
    )
  end

  def terminate
    permitted = params.permit(:person_id, :role_id)
    terminate_agency_staff = Operations::TerminateAgencyStaff.new(permitted[:person_id], permitted[:role_id])
    authorize terminate_agency_staff, :terminate_agency_staff?
    case terminate_agency_staff.call
    when :ok
      render json: { status: "success" }, status: 200
    when :person_not_found
      render json: { status: "error" }, status: 404
    when :no_role_found
      render json: { status: "error", message: "Unable to find role" }, status: 422
    else
      render json: { status: "error" }, status: 409
    end
  end

  def update_person
    operation = Operations::UpdateStaff.new(update_person_params)
    authorize operation, :update_staff?
    case operation.update_person
    when :ok
      render json: { status: "success", message: 'Succesfully updated!!' }, status: 200
    when :person_not_found
      render json: { status: "error", message: "Updating Staff Failed. Person Not Found" }, status: 404
    when :information_missing
      render json: { status: "error", message: "Updating Staff Failed. Required properties missing" }, status: 404
    when :matching_record_found
      render json: { status: "error", message: "Updating Staff Failed. Given details matces with another record. Contact Admin" }, status: 422
    else
      render json: { status: "error", message: "Unexpected Error" }, status: 409
    end
  end

  def update_email
    operation = Operations::UpdateStaff.new(update_email_params)
    authorize operation, :update_staff?
    case operation.update_email
    when :ok
      render json: { status: "success", message: 'Succesfully updated!!' }, status: 200
    when :person_not_found
      render json: { status: "error", message: "Updating Staff Failed. Person Not Found" }, status: 404
    when :email_not_found
      render json: { status: "error", message: "Updating Staff Failed. Email not found" }, status: 422
    else
      render json: { status: "error", message: "Unexpected Error" }, status: 409
    end
  end

  private

  def update_person_params
    params.permit(:person_id, :dob, :first_name, :last_name)
  end

  def update_email_params
    params.permit(:person_id, emails: [:id, :address])
  end
end
