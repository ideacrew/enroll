require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_broker_assignment")


describe RemoveBrokerAssignment do
  let(:given_task_name) { "remove_broker_assignment" }
  subject { RemoveBrokerAssignment.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "should remove broker agency for the family with given primary person's hbx_id" do
    let(:person_fam) { FactoryGirl.create(:person, :with_family, hbx_id: "1234567890")}
    let(:family) { person_fam.primary_family }
    let(:person) { FactoryGirl.create(:person)}
    let(:organization) {FactoryGirl.create(:organization)}
    let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, organization: organization) }
    let(:broker_agency_staff_role) {FactoryGirl.build(:broker_agency_staff_role, broker_agency_profile: broker_agency_profile)}
    let(:broker_role) { FactoryGirl.create(:broker_role,  broker_agency_profile: broker_agency_profile, aasm_state: 'active')}
    let(:person_broker) {broker_agency_staff_role.person}

    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return("1234567890")
    end

    it "should remove broker assignment for the family" do
      family.hire_broker_agency(broker_role.id)
      family.save
      expect(family.current_broker_agency.present?).to be_truthy
      subject.migrate
      family.reload
      expect(family.current_broker_agency.present?).to be_falsey
    end
  end
end
