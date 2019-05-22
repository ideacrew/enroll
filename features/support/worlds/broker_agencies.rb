module BrokerAgencies
  def create_broker_agency
    person = FactoryGirl.create(:person)
    @person2 = FactoryGirl.create(:person, first_name: 'staff', last_name: 'member')
    user2 = FactoryGirl.create(:user, person: @person2)
    @user ||= User.create( email: 'hbx_admin_role@dc.gov', password: 'P@55word', password_confirmation: 'P@55word', oim_id: 'hbx_admin_role@dc.gov', person: person)
    organization = FactoryGirl.create(:organization, legal_name: 'Logistics Inc' )
    @broker_agency_profile ||= FactoryGirl.create(:broker_agency_profile, aasm_state: 'is_approved', organization: organization)
    broker_role = FactoryGirl.create(:broker_role, broker_agency_profile_id: @broker_agency_profile.id, person: person)
    broker_agency_staff_role = FactoryGirl.build(:broker_agency_staff_role, broker_agency_profile_id: @broker_agency_profile.id,)
    person.broker_agency_staff_roles << broker_agency_staff_role
  end
end
World(BrokerAgencies)

Given(/^Broker Agency exists in Enroll$/) do
  create_broker_agency
end