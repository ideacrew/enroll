require "rails_helper"
require 'byebug'
require File.join(Rails.root, "app", "data_migrations", "delink_employee_role")

describe DelinkEmployeeRole, dbclean: :after_each do
  let(:given_task_name) { "delink_employee_role" }
  subject { DelinkEmployeeRole.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "delink the employee role for the person" do
    let(:census_employee_id) { "abcdefg" }
    let(:correct_person) { FactoryGirl.create(:person) }
    let!(:employer_profile) { FactoryGirl.create(:employer_profile)}
    let!(:employee_roles) { FactoryGirl.create(:employee_role, employer_profile: employer_profile, census_employee_id: census_employee.id, person: correct_person) }
    let!(:census_employee) { FactoryGirl.create(:census_employee)}
    before(:each) do
       ENV["correct_person_hbx_id"] = correct_person.hbx_id
    end

  it "should add general agency staff role to the correct_person account" do
    expect(correct_person.employee_roles.first.census_employee_id.present?).to eq true
    subject.migrate
    correct_person.reload
    expect(correct_person.employee_roles.first.census_employee_id.present?).to eq false
    end
end
end