require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'change_fein')

describe ChangeFein, dbclean: :after_each do
  let(:given_task_name) { 'change_fein' }
  subject { ChangeFein.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'changing organization fein' do
    let(:organization) { FactoryBot.create(:organization)}

    it 'should change effective on date' do
      ClimateControl.modify old_fein: organization.fein, new_fein: '987654321' do
        fein=organization.fein
        expect(organization.fein).to eq fein
        subject.migrate
        organization.reload
        expect(organization.fein).to eq '987654321'
      end
    end
  end
end
