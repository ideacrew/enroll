require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_employee_role_id")
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe UpdateEmployeeRoleId, dbclean: :after_each do
  let(:given_task_name) { "update_employee_role_id" }
  subject { UpdateEmployeeRoleId.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "update employee role id on the enrollments/census_employee", dbclean: :after_each do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:current_effective_date)  { TimeKeeper.date_of_record.beginning_of_month.prev_year }
    let(:start_on)  { TimeKeeper.date_of_record.beginning_of_month.prev_month }
    let(:effective_period)    { start_on..start_on.next_year.prev_day }
    let(:benefit_application) { initial_application }

    let(:benefit_package) { current_benefit_package }
    let(:benefit_group_assignment) {FactoryGirl.build(:benefit_sponsors_benefit_group_assignment, benefit_group: benefit_package)}

    let(:employee_role) { FactoryGirl.create(:benefit_sponsors_employee_role, person: person, employer_profile: benefit_sponsorship.profile, census_employee_id: census_employee.id) }
    let(:census_employee) { FactoryGirl.create(:benefit_sponsors_census_employee,
      employer_profile: benefit_sponsorship.profile,
      benefit_sponsorship: benefit_sponsorship,
      benefit_group_assignments: [benefit_group_assignment]    )}
    let(:person) { FactoryGirl.create(:person) }
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}

    let!(:hbx_enrollment) do
      FactoryGirl.create(:hbx_enrollment,
                         household: family.active_household,
                         kind: "employer_sponsored",
                         effective_on: start_on,
                         employee_role_id: "111111111",
                         sponsored_benefit_package_id: benefit_package.id,
                         benefit_group_assignment_id: benefit_group_assignment.id,
                         aasm_state: 'coverage_selected'
      )
    end
    context 'update employee role id on the enrollments', dbclean: :after_each  do
      before :each do
        ENV["hbx_id"] = person.hbx_id
        ENV['action'] = "update_employee_role_id_to_enrollment"
        employee_role.person.save!
      end
      it "should update the ee_role_id on hbx_enrollment with the correct one" do
        expect(person.active_employee_roles.first.id).not_to eq hbx_enrollment.employee_role_id
        subject.migrate
        hbx_enrollment.reload
        expect(person.active_employee_roles.first.id).to eq hbx_enrollment.employee_role_id
      end

      it "should not change the ee_role_id of hbx_enrollment if the EE Role id matches with the correct one" do
        hbx_enrollment.update_attributes(:employee_role_id => employee_role.id)
        expect(person.active_employee_roles.first.id).to eq hbx_enrollment.employee_role_id
        subject.migrate
        hbx_enrollment.reload
        expect(person.active_employee_roles.first.id).to eq hbx_enrollment.employee_role_id
      end
    end
    context 'update employee role id on the census_employee', dbclean: :after_each  do
      before :each do
        ENV["hbx_id"] = person.hbx_id
        ENV['action'] = "update_employee_role_id_to_ce"
        employee_role.person.save!
        person.active_employee_roles.first.census_employee.update_attributes!(employee_role_id: employee_role.id )
      end
      it "should update the ee_role_id on census_employee if the id on EE role is not similar" do
        person.active_employee_roles.first.census_employee.update_attributes!(employee_role_id: "111111111111111111111111")
        expect(person.active_employee_roles.first.id).not_to eq person.active_employee_roles.first.census_employee.employee_role_id
        subject.migrate
        person.employee_roles.first.census_employee.reload
        expect(person.active_employee_roles.first.id).to eq person.active_employee_roles.first.census_employee.employee_role_id
      end

      it "should not change the ee_role_id of census_employee if the id on EE role is similar" do
        expect(person.active_employee_roles.first.id).to eq person.active_employee_roles.first.census_employee.employee_role_id
        subject.migrate
        person.employee_roles.first.census_employee.reload
        expect(person.active_employee_roles.first.id).to eq person.active_employee_roles.first.census_employee.employee_role_id
      end
    end
  end
end