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

    it "should send reminder notice when due date is great than or eq to 30 days" do
      allow(family).to receive(:best_verification_due_date).and_return(TimeKeeper.date_of_record+30)
      expect(IvlNoticesNotifierJob).to receive(:perform_later).at_least(1).times
      Rake::Task["recurring:ivl_reminder_notices"].invoke
    end

    it "should NOT send reminder notice when due date is less than or eq to 30 days" do
      allow(family).to receive(:best_verification_due_date).and_return(TimeKeeper.date_of_record+20)
      expect(IvlNoticesNotifierJob).not_to receive(:perform_later)
      Rake::Task["recurring:ivl_reminder_notices"].invoke
    end
  end
end