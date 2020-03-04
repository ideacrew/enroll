class Api::V1::AgenciesController < Api::V1::ApiBaseController

  before_action :authenticate_user!, only: [:index, :agency_staff, :primary_agency_staff]

  def index
    query = Queries::AgenciesQuery.new
    render json: query.to_json(
             :only => [:dba, :legal_name],
             :methods => [:agency_profile_id, :organization_id, :agency_profile_type]
           )
  end

  def agency_staff
    query = Queries::People::NonPrimaryAgentsQuery.new
    render json: query.to_json(
      :only => [:_id,:first_name, :last_name, :hbx_id, :dob],
      :methods => [:agency_roles, :agent_emails]
    )
  end

  def primary_agency_staff
    query = Queries::People::PrimaryAgentsQuery.new
    render json: query.to_json(
      :only => [:first_name, :last_name, :hbx_id],
      :methods => [:agent_npn, :agent_role_id, :connected_profile_id]
    )
  end

  def terminate
    permitted = params.permit(:person_id, :role_id)
    role = BrokerAgencyStaffRole.find(permitted[:role_id]) || GeneralAgencyStaffRole.find(permitted[:role_id])
    begin
      if role.class.name == "BrokerAgencyStaffRole"
        role.broker_agency_terminate!
      else
        role.general_agency_terminate!
      end
      render json: {status: "success"}
    rescue
      render json: {status: "error"}
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
