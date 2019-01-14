require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "ee_without_employee_role")

describe EeWithoutEmployeeRole, dbclean: :after_each do

  let(:given_task_name) { "ee_without_employee_role" }
  subject { EeWithoutEmployeeRole.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "assign employee role", dbclean: :after_each do
    let(:person) { FactoryBot.create(:person)}
    let(:benefit_group) { FactoryBot.create(:benefit_group)}
    let(:active_plan_year)  { FactoryBot.build(:plan_year, aasm_state: 'active', benefit_groups: [benefit_group])}
    let(:employer_profile) { FactoryBot.create(:employer_profile, plan_years: [active_plan_year])}
    let(:organization) { FactoryBot.create(:organization, employer_profile:employer_profile)}
    let(:census_employee1) { FactoryBot.create(:census_employee, employer_profile:employer_profile)}
    let(:census_employee2) { FactoryBot.create(:census_employee, aasm_state:'eligible', employer_profile:employer_profile)}
    let(:employee_role1) { FactoryBot.create(:employee_role, person:person, census_employee:census_employee1, employer_profile_id:employer_profile.id)}
    let(:employee_role2) { FactoryBot.create(:employee_role, person:person, census_employee:census_employee2, employer_profile_id:employer_profile.id)}

    before do
      allow(person).to receive(:employee_roles).and_return([employee_role1, employee_role2])
      census_employee1.update_attributes!(aasm_state:"rehired", employee_role_id: employee_role1.id)
    end

    context "for census employee without an employee role" do

      it "should link employee role" do
        expect(census_employee2.employee_role).to eq nil # before migration
        subject.migrate
        census_employee2.reload
        expect(census_employee2.employee_role).to eq employee_role2 # after migration
      end
    end
  end
end
