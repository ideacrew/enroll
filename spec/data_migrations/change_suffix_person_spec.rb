require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'change_suffix_person')
describe ChangeSuffixPerson do
  let(:given_task_name) { 'change_suffix_person' }
  subject { ChangeSuffixPerson.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end
  describe 'changing person name suffix ' do
    let(:person) { FactoryBot.create(:person, name_sfx: nil)}
    let(:hbx_id) { person.hbx_id}

    it 'should change person suffix name' do
      ClimateControl.modify hbx_ids: hbx_id do
        name_sfx=person.name_sfx
        expect(person.name_sfx).to eq name_sfx
        subject.migrate
        person.reload
        expect(person.name_sfx).to eq name_sfx
      end
    end
  end
end
