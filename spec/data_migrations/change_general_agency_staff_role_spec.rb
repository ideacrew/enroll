require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_general_agency_staff_role")

describe ChangeGeneralAgencyStaffRole, dbclean: :after_each do
  let(:given_task_name) { "change_general_agency_staff_role" }
  subject { ChangeGeneralAgencyStaffRole.new(given_task_name, double(:current_scope => nil)) }
  before do
    EnrollRegistry[:general_agency].feature.stub(:is_enabled).and_return(true)
  end
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "change the general agency staff role" do
    let(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role) }
    let(:incorrect_person) {FactoryBot.create(:person) }
    let(:correct_person) { FactoryBot.create(:person) }

    it "should add general agency staff role to the correct_person account" do
      ClimateControl.modify incorrect_person_hbx_id: incorrect_person.hbx_id,correct_person_hbx_id: correct_person.hbx_id do
        incorrect_person.general_agency_staff_roles << general_agency_staff_role
        expect(incorrect_person.general_agency_staff_roles.present?).to be_truthy
        expect(correct_person.general_agency_staff_roles.present?).to eq false
        subject.migrate
        incorrect_person.reload
        correct_person.reload
        expect(correct_person.general_agency_staff_roles.count).to eq 1
        expect(incorrect_person.general_agency_staff_roles.present?).to eq false
      end
    end
  end
end
