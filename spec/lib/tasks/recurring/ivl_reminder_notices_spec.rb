require 'rails_helper'
require 'rake'

describe 'recurring:ivl_reminder_notices', :dbclean => :around_each do
  let(:family) { FactoryGirl.create(:individual_market_family)}
  let(:hbx_enrollment) { double("HbxEnrollment") }
  let(:person) {family.primary_applicant.person}
  let(:consumer_role) {person.consumer_role}
  before do
  allow(Family).to receive(:where).and_return([family])
    allow(family).to receive_message_chain(:enrollments,:order,:select,:first).and_return(hbx_enrollment)
    allow(hbx_enrollment).to receive(:special_verification_period).and_return(DateTime.now + 84.days)
    load File.expand_path("#{Rails.root}/lib/tasks/recurring/ivl_reminder_notices.rake", __FILE__)
    Rake::Task.define_task(:environment)
  end
  context "when reminder not sent" do
    before do
      allow(person).to receive_message_chain(:documents,:detect).and_return(false)
    end

    it "should send reminder notice" do
      expect(consumer_role).to receive(:first_verifications_reminder).at_least(1).times
      expect(consumer_role).to receive(:second_verifications_reminder).at_least(1).times
      expect(consumer_role).to receive(:third_verifications_reminder).at_least(1).times
      expect(consumer_role).to receive(:fourth_verifications_reminder).at_least(1).times
      Rake::Task["recurring:ivl_reminder_notices"].invoke
    end
  end

  context "when reminder already sent" do
    before do
      allow(person).to receive_message_chain(:documents,:detect).and_return(true)
    end

    it "should NOT send reminder notice" do
      expect(consumer_role).not_to receive(:first_verifications_reminder)
      expect(consumer_role).not_to receive(:second_verifications_reminder)
      expect(consumer_role).not_to receive(:third_verifications_reminder)
      expect(consumer_role).not_to receive(:fourth_verifications_reminder)
      Rake::Task["recurring:ivl_reminder_notices"].invoke
    end
  end
end