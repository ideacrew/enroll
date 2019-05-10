require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'add_broker_agency_staff_role_for_broker')

describe AddBrokerAgencyStaffRoleForBroker, dbclean: :after_each do

  let(:given_task_name) { 'add_broker_agency_staff_role_for_broker' }
  subject { AddBrokerAgencyStaffRoleForBroker.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'Add broker staff role', dbclean: :after_each do

    let!(:user) { FactoryGirl.create(:user) }

    let!(:person_with_staff_role) { FactoryGirl.create(:person) }
    let!(:person_with_no_staff_role) { FactoryGirl.create(:person, user: user) }
    let!(:broker_role1) { FactoryGirl.create(:broker_role, aasm_state: 'active', person: person_with_staff_role, broker_agency_profile: broker_agency_profile) }
    let!(:broker_role2) { FactoryGirl.create(:broker_role, aasm_state: 'active', person: person_with_no_staff_role, broker_agency_profile: broker_agency_profile) }
    let!(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, aasm_state: 'is_approved')}
    let!(:broker_agency_staff_role) { FactoryGirl.create(:broker_agency_staff_role, aasm_state: 'active', broker_agency_profile: broker_agency_profile, person: person_with_staff_role)  }


    it 'should add a broker staff role for broker with user record' do
      expect(person_with_staff_role.broker_agency_staff_roles.count).to eq 1
      expect(person_with_no_staff_role.broker_agency_staff_roles).to eq []
      subject.migrate
      person_with_no_staff_role.reload
      person_with_staff_role.reload
      expect(person_with_staff_role.broker_agency_staff_roles.count).to eq 1
      expect(person_with_no_staff_role.broker_agency_staff_roles.count).to eq 1
      expect(person_with_no_staff_role.broker_agency_staff_roles.first.aasm_state).to eq 'active'
    end
  end
end
