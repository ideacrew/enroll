class Api::V1::AgenciesController < Api::V1::ApiBaseController

  #before_action :authenticate_user!

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
    permitted = params.permit(:person_id, :dob)
    person = Person.find(permitted[:person_id])
    person.update_attributes({dob: permitted[:dob]})
    render json: { status: "person object updated" }, status: 200
  end

  def update_email
    render json: { status: "email updated" }, status: 200
  end

end
