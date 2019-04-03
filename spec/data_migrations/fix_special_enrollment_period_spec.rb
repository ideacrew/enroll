require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
require File.join(Rails.root, 'app', 'data_migrations', 'fix_special_enrollment_period.rb')

describe FixSpecialEnrollmentPeriod, dbclean: :after_each do
  let(:given_task_name) { 'fix_special_enrollment_period' }
  subject { FixSpecialEnrollmentPeriod.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'fix sep invalid records' do
    include_context 'setup benefit market with market catalogs and product packages'
    include_context 'setup initial benefit application'

    let(:person) {FactoryBot.create(:person, :with_family, :with_ssn)}
    let(:family) { person.primary_family }
    let(:census_employee) { FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package ) }
    let(:employee_role) { FactoryBot.create(:employee_role, person: person, census_employee_id: census_employee.id, employer_profile: abc_profile) }
    let(:add_emp_role) {person.employee_roles = [employee_role]
      person.save
    }
    let(:special_enrollment_period) {FactoryBot.build(:special_enrollment_period, family: family, optional_effective_on:[Date.strptime(initial_application.start_on.to_s, "%m/%d/%Y").to_s])}
    let(:add_special_enrollemt_period) {family.special_enrollment_periods = [special_enrollment_period]
                                          family.save
    }

    before(:each) do
      allow(person).to receive(:active_employee_roles).and_return [employee_role]
      special_enrollment_period.next_poss_effective_date=[initial_application.end_on.next_day.to_s]
      special_enrollment_period.save(validate:false) # adding error next_poss_effective_date.
    end

    it 'should fix next_poss_effective_date validation and update with valid plan year' do
      ClimateControl.modify person_hbx_id: person.hbx_id do
        expect(family.special_enrollment_periods.map(&:valid?)).to eq [false]  # before migration
        subject.migrate
        special_enrollment_period.reload
        expect(family.special_enrollment_periods.map(&:valid?)).to eq [true]  # after migration
        expect(special_enrollment_period.next_poss_effective_date).to eq initial_application.end_on
      end
    end
  end
end
