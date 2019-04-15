require 'rails_helper'

describe TerminateCensusEmployeeWithNoHbxEnrollment, dbclean: :after_each do

  describe 'given a task name' do
    let(:given_task_name) { 'terminate_census_employee_with_no_hbx_enrollment' }
    subject { TerminateCensusEmployeeWithNoHbxEnrollment.new(given_task_name, double(:current_scope => nil)) }

    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'census employee employment_terminated_on with past date' do
    subject { TerminateCensusEmployeeWithNoHbxEnrollment.new('terminate_census_employee_with_no_hbx_enrollment', double(:current_scope => nil)) }

    let(:person){ FactoryBot.create(:person, :with_employee_role) }
    let(:employee_role) { person.employee_roles.first }
    let(:census_employee) { FactoryBot.create(:census_employee, employer_profile_id: employee_role.employer_profile.id, hired_on: "2014-11-11", employee_role_id: employee_role.id) }
    let(:employment_terminated_on) { TimeKeeper.date_of_record - 1.day }

    it 'census employee should termianated' do
      ClimateControl.modify "hbx_id" => person.hbx_id, "employment_terminated_on" => employment_terminated_on.strftime("%Y-%m-%d") do
        census_employee.terminate_employment(employment_terminated_on)
        subject.migrate
        expect(census_employee.aasm_state).to eq 'employment_terminated'
        expect(census_employee.employment_terminated_on).to eq employment_terminated_on
      end
    end
  end
end
