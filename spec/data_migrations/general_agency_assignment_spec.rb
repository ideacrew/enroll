require "rails_helper"
if ExchangeTestingConfigurationHelper.general_agency_enabled?
require File.join(Rails.root, "app", "data_migrations", "general_agency_assignment")

describe GeneralAgencyAssignment, dbclean: :around_each do

  let(:given_task_name) { "general_agency_assignment" }
  subject { GeneralAgencyAssignment.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "general agency profile assignment for employer" do

    let!(:new_plan_year){ FactoryBot.create(:plan_year, aasm_state: "active", employer_profile: employer_profile) }
    let(:broker_agency_profile) { FactoryBot.create(:broker_agency_profile) }
    let(:general_agency_account) { FactoryBot.create(:general_agency_account) }
    let(:broker_agency_account) { BrokerAgencyAccount.new(broker_agency_profile_id: broker_agency_profile.id, start_on: TimeKeeper.date_of_record, is_active: true)}
    let(:employer_profile){ FactoryBot.create(:employer_profile, broker_agency_accounts: [broker_agency_account]) }
    let(:end_on) { new_plan_year.open_enrollment_end_on }

    it "should assign general agency profile for employer" do
      ClimateControl.modify general_agency_id: general_agency_account.general_agency_profile_id.to_s, employer_profile_id: employer_profile.id.to_s, broker_agency_id: broker_agency_profile.id.to_s, open_enrollment_end_on: end_on.to_s, aasm_state: "active" do
        expect(employer_profile.general_agency_accounts.present?).to eq false
        subject.migrate
        employer_profile.reload
        expect(employer_profile.general_agency_accounts.present?).to eq true
      end
    end
  end
end
end
