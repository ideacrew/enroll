require "rails_helper"
require File.join(Rails.root, 'app', 'data_migrations', 'updating_person_ssn')

describe ChangeFein, dbclean: :around_each do
  let(:given_task_name) { 'updating_person_ssn' }
  subject { UpdatingPersonSsn.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'change person ssn' do
    let(:person1){ FactoryBot.create(:person, ssn:"787878787")}

    it 'should change person ssn' do
      ClimateControl.modify hbx_id_1: person1.hbx_id, person_ssn: person1.ssn do
        ssn=person1.ssn
        subject.migrate
        person1.reload
        expect(person1.ssn).to eq ssn
      end
    end
  end
end
