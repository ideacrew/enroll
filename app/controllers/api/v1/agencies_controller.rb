class Api::V1::AgenciesController < Api::V1::ApiBaseController

  def index
    render json: BenefitSponsors::Organizations::Organization.all_agency_profiles
      .to_json(
             :only => [:dba, :legal_name],
             :methods => [:agency_profile_id, :organization_id, :agency_profile_type]
           )
  end

  def agency_staff
      render json: Person.api_staff_roles.to_json(
      :only => [:_id, :profiles, :first_name, :last_name, :hbx_id, :dob],
      :methods => [:agency_roles, :agent_emails])
  end

  def primary_agency_staff
      render json: Person.api_primary_staff_roles.to_json(
      :only => [:profiles, :first_name, :last_name],
      :methods => [:agent_npn, :agent_role_id])
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
