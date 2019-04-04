require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'updating_person_phone_number')

describe UpdatingPersonPhoneNumber, dbclean: :after_each do

  let(:given_task_name) { 'update_broker_phone_kind' }
  subject { UpdatingPersonPhoneNumber.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'changing broker phone kind' do  
     let(:phone) {FactoryBot.build(:phone, kind:'work')}
     let(:person) { FactoryBot.create(:person,phones:[phone]) }

    it 'should change the employee contribution' do
      ClimateControl.modify hbx_id: person.hbx_id, area_code: '302', number: '4667333', ext: '', full_number: '3014667333' do
        subject.migrate
        person.reload
        expect(person.phones.where(kind:'work').first.full_phone_number).to eq '3014667333'
      end
    end
  end
end
