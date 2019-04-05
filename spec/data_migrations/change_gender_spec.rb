require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'change_gender')

describe ChangeGender, dbclean: :after_each do

  let(:given_task_name) { 'change_gender' }
  subject { ChangeGender.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'changing gender for an Employee', dbclean: :after_each do
    let(:person) { FactoryBot.create(:person, gender: 'male') }
    let(:employer_profile) { FactoryBot.create(:employer_profile)}
    let(:census_employee) { FactoryBot.create(:census_employee, employer_profile: employer_profile, gender: 'male') }

    it 'should change the gender' do
      ClimateControl.modify hbx_id: person.hbx_id, id: census_employee.id, gender: 'female' do
        subject.migrate
        census_employee.reload
        person.reload
        expect(census_employee.gender).to eq 'female'
        expect(person.gender).to eq 'female'
      end
    end
  end
end
