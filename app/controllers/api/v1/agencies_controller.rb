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

  # TODO: The below need proper queries and/or commands.
  def agency_staff_detail
    render json: Person.find(params[:person_id]).to_json(
      :only => [:_id, :first_name, :last_name, :hbx_id, :dob],
      :methods => [:agency_roles, :agent_emails]
    )
  end

  def terminate
    permitted = params.permit(:person_id, :role_id)
    begin
      person = Person.find(permitted[:person_id])
      role_id = permitted[:role_id]
      role = person.broker_agency_staff_roles.select{ |role| role._id.to_s == role_id }.first ||
             person.general_agency_staff_roles.select{ |role| role._id.to_s == role_id }.first
      if role
        role.class.name == "BrokerAgencyStaffRole" ? role.broker_agency_terminate! : role.general_agency_terminate!
        render json: { status: "success" }, status: 200
      else
        render json: { status: "error", message: "Unable to find role" }, status: 409
      end
    rescue
      render json: { status: "error" }, status: 409
    end
  end

  def approve_general_agency_staff
    #{"person_id"=>"5e4954c7b0b6c5c34cc4110e", "profile_id"=>"5e4953d3b0b6c5c34cc410f5", "id"=>"5e4953d3b0b6c5c34cc410f5"}
    # @staff = BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.for_approve(general_agency_staff_params)
    # authorize @staff
    # begin
    #   @status, @result = @staff.approve
    #   if @status
    #     flash[:notice] = "Role approved successfully"
    #   else
    #     flash[:error] = "Role was not approved because " + @result
    #   end
    # rescue Exception => e
    #   flash[:error] = "Role was not approved because " + e.message
    # end
    # redirect_to profiles_general_agencies_general_agency_profile_path(id: params[:staff][:profile_id])
  end
end
