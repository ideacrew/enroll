require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_duplicate_broker_agency_accounts")

describe RemoveDuplicateBrokerAgencyAccounts do
  let(:given_task_name) { "remove_duplicate_broker_agency_accounts" }
  let(:employer_profile1) {FactoryGirl.create(:employer_profile, organization: organization)}
  let(:broker_agency_account) {FactoryGirl.create(:broker_agency_account, broker_agency_profile: broker_agency_profile,employer_profile: employer_profile1)}
  let(:broker_agency_account2) {FactoryGirl.create(:broker_agency_account, broker_agency_profile: broker_agency_profile,employer_profile: employer_profile1)}
  let(:organization) {FactoryGirl.create(:organization)}
  let(:broker_agency_profile) {FactoryGirl.create(:broker_agency_profile, organization: organization)}
  let!(:family) {FactoryGirl.create(:family, :with_primary_family_member, broker_agency_accounts:[broker_agency_account, broker_agency_account2])}
  
  subject { RemoveDuplicateBrokerAgencyAccounts.new(given_task_name, double(:current_scope => nil)) }
  
  it "should get remove duplicate broker agency accounts from families" do
    expect(family.broker_agency_accounts.size).to eq 2
    subject.migrate
    family.reload
    expect(family.broker_agency_accounts.size).to eq 1
  end
    
end