require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'create_broker_agency_account_for_employer')

describe CreateBrokerAgencyAccountForEmployer, dbclean: :after_each do
  let(:given_task_name) { 'create_broker_agency_account_for_employer' }
  subject { CreateBrokerAgencyAccountForEmployer.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'should create broker_agency_accounts for employer' do
    let!(:employer_profile) { FactoryBot.build(:employer_profile)}
    let!(:organization) { FactoryBot.create(:organization,employer_profile:employer_profile)}
    let!(:broker_agency_profile) { FactoryBot.build(:broker_agency_profile)}
    let!(:br_agency_organization) { FactoryBot.create(:organization,broker_agency_profile:broker_agency_profile)}
    let!(:broker_role) { FactoryBot.create(:broker_role,languages_spoken: ['rrrrr'],broker_agency_profile_id:broker_agency_profile.id, aasm_state:'active')}

    before(:each) do
      allow(br_agency_organization.broker_agency_profile).to receive(:active_broker_roles).and_return([broker_role])
    end

    it 'should have broker_agency_account for employer' do
      ClimateControl.modify emp_hbx_id: organization.hbx_id, br_agency_hbx_id: br_agency_organization.hbx_id, br_npn: broker_role.npn, br_start_on: TimeKeeper.date_of_record.to_s do
        expect(employer_profile.broker_agency_accounts.size).to eq 0 # before migration
        subject.migrate
        employer_profile.reload
        expect(employer_profile.broker_agency_accounts.size).to eq 1 
      end# after migration
    end
  end
end
