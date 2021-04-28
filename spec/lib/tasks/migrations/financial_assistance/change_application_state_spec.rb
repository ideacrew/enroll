require 'rails_helper'
Rake.application.rake_require "tasks/migrations/financial_assistance/change_application_state"
Rake::Task.define_task(:environment)

RSpec.describe 'Change Application State to terminated or cancelled', :type => :task, dbclean: :around_each do
  let(:family_id) { BSON::ObjectId.new }
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family_id) }
  let!(:application2) { FactoryBot.create(:financial_assistance_application, family_id: family_id, aasm_state: 'draft') }

  context "invoking rake" do
    it "should update aasm_state of the application to terminated" do
      expect(application.aasm_state).to eq('determined')
      ENV['hbx_id'] = application.hbx_id
      ENV['action'] = "terminate"
      Rake::Task["migrations:change_application_state"].invoke
      application.reload
      expect(application.aasm_state).to eq('terminated')
    end

    it "should update aasm_state of the application to cancelled" do
      expect(application.aasm_state).to eq('determined')
      ENV['hbx_id'] = application.hbx_id
      ENV['action'] = "cancel"
      Rake::Task["migrations:change_application_state"].reenable
      Rake::Task["migrations:change_application_state"].invoke
      application.reload
      expect(application.aasm_state).to eq('cancelled')
    end

    it "should update multiple applications" do
      expect(application.aasm_state).to eq('determined')
      expect(application2.aasm_state).to eq('draft')

      ENV['hbx_id'] = "#{application.hbx_id},#{application2.hbx_id}"

      ENV['action'] = "terminate"
      Rake::Task["migrations:change_application_state"].reenable
      Rake::Task["migrations:change_application_state"].invoke
      application.reload
      application2.reload
      expect(application.aasm_state).to eq('terminated')
      expect(application2.aasm_state).to eq('terminated')
    end
  end
end
