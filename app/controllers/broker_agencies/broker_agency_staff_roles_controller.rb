class BrokerAgencies::BrokerAgencyStaffRolesController < ApplicationController

  before_action :check_access_to_broker_agency_profile


  def new
  end

  def create
    dob = DateTime.strptime(params[:person][:dob], '%m/%d/%Y').try(:to_date)
    broker_agency_profile = BrokerAgencyProfile.find(params[:id])
    first_name = (params[:person][:first_name] || '').strip
    last_name = (params[:person][:last_name] || '').strip
    email = params[:email]
    @status, @result = Person.add_broker_agency_staff_role(first_name, last_name, dob, email, broker_agency_profile)
    @status ? (flash[:notice] = 'Role added successfully') : (flash[:error] = ('Role was not added because '  + @result))
    redirect_to broker_agencies_profile_path(broker_agency_profile)
  end

  def approve
    person = Person.find(params[:staff_id])
    role = person.broker_agency_staff_roles.detect{|role| role.agency_pending? && role.broker_agency_profile_id.to_s == params[:id]}
    if role && role.approve && role.save!
      flash[:success] =  'Role is approved'
    else
      flash[:error] =  'Please contact HBX Admin to report this error'
    end
    redirect_to broker_agencies_profile_path(id: params[:id])
  end

  def destroy
    broker_agency_profile_id = params[:id]
    broker_agency_profile = BrokerAgencyProfile.find(broker_agency_profile_id)
    staff_id = params[:staff_id]
    staff_list =Person.staff_for_broker(broker_agency_profile).map(&:id)

    if staff_list.count == 1 && staff_list.first.to_s == staff_id
      flash[:error] = 'Please add another staff role before deleting this role'
    else
      @status, @result = Person.deactivate_broker_agency_staff_role(staff_id, broker_agency_profile_id)
      @status ? (flash[:notice] = 'Staff role was deleted') : (flash[:error] = ('Role was not deactivated because '  + @result))
    end

    redirect_to broker_agencies_profile_path(id: params[:id])
  end

  def redirect_to_new
    redirect_to new_broker_agency_broker_agencies_broker_roles_path
  end

  private

  def check_access_to_broker_agency_profile
    broker_agency_profile = BrokerAgencyProfile.find(params[:id])
    policy = ::AccessPolicies::BrokerAgencyProfile.new(current_user)
    policy.authorize_edit(broker_agency_profile, self)
  end

end
