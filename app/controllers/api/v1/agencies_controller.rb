class Api::V1::AgenciesController < Api::V1::ApiBaseController

  def index
    render json: BenefitSponsors::Organizations::Organization
      .all_agency_profiles
      .to_json(:include => {
          :profiles => {
            :methods => [:profile_type]
          }
        }
      )
  end


  def agency_staff
    #@general_agency_profile = ::BenefitSponsors::Organizations::GeneralAgencyProfile.find(params[:id])
    render json: Person.all_agency_staff_roles.to_json
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
