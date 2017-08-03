require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "correct_broker_ivl_families")

describe CorrectBrokerIvlFamilies, dbclean: :after_each do
  let(:given_task_name) { "correct_broker_ivl_families" }
  subject { CorrectBrokerIvlFamilies.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "employer profile with broker agency accounts", dbclean: :after_each do
    let(:person) { FactoryGirl.create(:person,:with_broker_role,:with_family)}
    let(:organization) {FactoryGirl.create(:organization)}
    let(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization)}
    let(:broker_agency_profile) {FactoryGirl.create(:broker_agency_profile, organization: organization)}
    let(:broker_agency_account) {FactoryGirl.create(:broker_agency_account, broker_agency_profile: broker_agency_profile, writing_agent_id: person.broker_role.id, is_active: true, employer_profile: employer_profile)}
    let(:broker_role) { FactoryGirl.create(:broker_role, :aasm_state => 'active', broker_agency_profile: broker_agency_profile) }
    
    before(:each) do
      allow(ENV).to receive(:[]).with("writing_agent_id").and_return(broker_role.id.to_s)
      allow(ENV).to receive(:[]).with("broker_agency_profile_id").and_return(broker_agency_account.id.to_s)
      allow_any_instance_of(Family).to receive(:current_broker_agency).and_return(broker_agency_account)
    end

    context "migrate" do
      it "broker_agency_profile needs to be update" do
        subject.migrate
        person.reload
        expect(person.primary_family.current_broker_agency.id.to_s).to eq broker_agency_account.id.to_s
      end
    end
  end
end


