require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_broker_phone_kind")

describe UpdateBrokerPhoneKind, dbclean: :after_each do

  let(:given_task_name) { "update_broker_phone_kind" }
  subject { UpdateBrokerPhoneKind.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing broker phone kind" do
    let!(:broker_agency_profile) { FactoryGirl.build(:broker_agency_profile)}
    let!(:br_agency_organization) { FactoryGirl.create(:organization,broker_agency_profile:broker_agency_profile)}
    let!(:broker_role) { FactoryGirl.create(:broker_role,languages_spoken: ["rrrrr"],broker_agency_profile_id:broker_agency_profile.id, aasm_state:'active')}


    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(br_agency_organization.fein)
      ph=br_agency_organization.broker_agency_profile.active_broker_roles.first.parent.phones.first
      ph.kind='mobile'
      ph.save!
    end

    it "should change the employee contribution" do
      expect(br_agency_organization.broker_agency_profile.active_broker_roles.first.parent.phones.first.kind).to eq 'mobile'
      subject.migrate
      br_agency_organization.reload
      expect(br_agency_organization.broker_agency_profile.active_broker_roles.first.parent.phones.first.kind).to eq 'work'
    end
  end
end
