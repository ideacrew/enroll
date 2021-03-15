require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_decertified_brokers_assignments")

describe RemoveDecertifiedBrokersAssignments do
  let(:given_task_name) { "remove_decertified_brokers_assignments" }
  let(:employer_profile) {FactoryBot.create(:employer_profile, organization: organization, general_agency_accounts:[general_agency_account])}
  let(:broker_agency_account) {FactoryBot.create(:broker_agency_account, broker_agency_profile: broker_agency_profile,employer_profile: employer_profile, writing_agent_id:broker_role.id)}
  let(:organization) {FactoryBot.create(:organization)}
  let(:broker_agency_profile) {FactoryBot.create(:broker_agency_profile, organization: organization, aasm_state: 'active', market_kind: :shop)}
  let(:general_agency_account) { FactoryBot.create(:general_agency_account, aasm_state: 'active') }
  let!(:family) {FactoryBot.create(:family, :with_primary_family_member, broker_agency_accounts:[broker_agency_account])}
  let(:broker_role) { FactoryBot.create(:broker_role,  broker_agency_profile: broker_agency_profile, aasm_state: 'active')}
  let(:broker_agency_staff_role) {FactoryBot.build(:broker_agency_staff_role, broker_agency_profile: broker_agency_profile)}
  let(:person) {broker_role.person}
  let(:fam_broker_agency_account) {BenefitSponsors::Accounts::BrokerAgencyAccount.new(start_on:Date.today,benefit_sponsors_broker_agency_profile_id:broker_agency_profile.id,is_active: true, writing_agent_id:broker_role.id)}
  subject { RemoveDecertifiedBrokersAssignments.new(given_task_name, double(:current_scope => nil)) }
  
  it "should get remove decertified/pending brokers from families/general agencies/employers" do
    family.broker_agency_accounts = [fam_broker_agency_account]
    family.save
    expect(family.current_broker_agency.is_active).to eq true
    expect(organization.employer_profile.active_broker_agency_account.present?).to eq true
    expect(organization.employer_profile.active_general_agency_account.present?).to eq true
    expect(person.broker_role.broker_agency_profile.employer_clients.size).to eq 1
    expect(person.broker_role.broker_agency_profile.families.size).to eq 1
    person.broker_role.decertify!
    subject.migrate
    person.reload
    family.reload
    organization.reload
    expect(family.current_broker_agency).to eq nil
    expect(organization.employer_profile.active_broker_agency_account).to eq nil
    expect(organization.employer_profile.active_general_agency_account).to eq nil
    expect(person.broker_role.broker_agency_profile.employer_clients.size).to eq 0
    expect(person.broker_role.broker_agency_profile.families.size).to eq 0
  end
    
end
