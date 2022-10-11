# frozen_string_literal: true

require 'rails_helper'
Rake.application.rake_require "tasks/update_data_text_notifications"
Rake::Task.define_task(:environment)

describe 'update_data:text_only_notification_to_text_and_paper', :dbclean => :around_each do
  let!(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let!(:person2) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let!(:person3) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  context "invoking rake" do
    before :each do
      person.consumer_role.contact_method = "Only Text Message communication"
      person.save!
      person2.consumer_role.contact_method = "Electronic and Text Message communications"
      person2.save!
      person3.consumer_role.contact_method = "Only Paper communication"
      person3.save!
    end

    it "should update person to be text and mail" do
      Rake::Task['update_data:text_only_notification_to_text_and_paper'].invoke
      person.reload
      expect(person.consumer_role.contact_method).to eq("Paper and Text Message communications")
    end

    it "should not update person with other options" do
      Rake::Task['update_data:text_only_notification_to_text_and_paper'].invoke
      person2.reload
      person3.reload
      expect(person2.consumer_role.contact_method).to eq("Electronic and Text Message communications")
      expect(person3.consumer_role.contact_method).to eq("Only Paper communication")
    end
  end
end