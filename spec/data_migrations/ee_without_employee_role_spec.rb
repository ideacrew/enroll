require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "ee_without_employee_role")

describe EeWithoutEmployeeRole do

  let(:given_task_name) { "ee_without_employee_role" }
  subject { EeWithoutEmployeeRole.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "assign employee role", dbclean: :after_each do
  
    let(:person) { FactoryGirl.create(:person, :with_employee_role)}
    let(:census_employee) { FactoryGirl.create(:census_employee, first_name: person.first_name, last_name: person.last_name,
      gender: person.gender, ssn: person.ssn, aasm_state: "eligible")}
    let(:employer_profile) { FactoryGirl.create(:employer_profile)}

    before(:each) do
      census_employee.update_attribute(:employer_profile_id, employer_profile.id)
    end

    context "for employee without an employee role" do

      it "should link employee role" do
        expect(census_employee.employee_role).to eq nil
        subject.migrate
        person.reload
        expect(census_employee.employee_role).not_to eq nil
      end
    end
  end
end
