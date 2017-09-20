require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_decertified_pending_brokers_from_families")

describe RemoveDuplicateBrokerAgencyAccounts do
  let(:given_task_name) { "remove_duplicate_broker_agency_accounts" }
  let(:employer_profile1) {FactoryGirl.create(:employer_profile, organization: organization)}
  let(:broker_agency_account) {FactoryGirl.create(:broker_agency_account, broker_agency_profile: broker_agency_profile,employer_profile: employer_profile1)}
  let(:organization) {FactoryGirl.create(:organization)}
  let(:broker_agency_profile) {FactoryGirl.create(:broker_agency_profile, organization: organization)}
  let!(:family) {FactoryGirl.create(:family, :with_primary_family_member, broker_agency_accounts:[broker_agency_account])}
  let(:broker_role) { FactoryGirl.create(:broker_role,  broker_agency_profile: broker_agency_profile, aasm_state: 'active')}
  
  subject { RemoveDertifiedPendingBrokersFromFamilies.new(given_task_name, double(:current_scope => nil)) }
    
  it "find families with decertified brokers and remover broker_agency_account" do
    family.current_broker_agency.writing_agent.update(aasm_state:"decertified")
    expect(family.broker_agency_accounts.size).to eq 1
    subject.migrate
    family.reload
    expect(family.broker_agency_accounts.size).to eq 0
  end
      
end