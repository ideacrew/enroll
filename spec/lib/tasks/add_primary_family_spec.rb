require 'rails_helper'
require 'rake'

describe 'update person', :dbclean => :around_each do
  describe 'update:person' do
    let(:person) { FactoryGirl.create(:person)}
    before do
      load File.expand_path("#{Rails.root}/lib/tasks/migrations/add_primary_family.rake", __FILE__)
      Rake::Task.define_task(:environment)
      hbx_id = person.hbx_id
      Rake::Task["person:update"].invoke(hbx_id)
    end
    it 'should create a family with person as primary applicant' do
      expect(person.primary_family.primary_applicant.person).to eq person
    end
  end
end
