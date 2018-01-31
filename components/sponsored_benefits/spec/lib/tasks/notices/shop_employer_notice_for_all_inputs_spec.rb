require 'rails_helper'
Rake.application.rake_require "tasks/notices/shop_employer_notice_for_all_inputs"
include ActiveJob::TestHelper
Rake::Task.define_task(:environment)

RSpec.describe 'Generate notices to employer by taking hbx_ids, feins, employer_ids and event name', :type => :task do
  let!(:employer_profile) { double(:employer_profile, id: "rspec-id") }
  let!(:organization) { double(:organization, employer_profile: employer_profile, hbx_id: "1231") }
  let!(:organization_hbx) { double(:organization, employer_profile: employer_profile, hbx_id: "131323") }
  let!(:organization_feins) { double(:organization, employer_profile: employer_profile, fein: "987") }

  before :each do
    $stdout = StringIO.new
    ActiveJob::Base.queue_adapter = :test
  end

  after(:all) do
    $stdout = STDOUT
  end

  after(:each) do
    Rake::Task['notice:shop_employer_notice_event'].reenable
  end

  context "Trigger Notice to employers" do
    it "when multiple hbx_ids input is given should trigger twice" do
      ENV['event'] = "rspec-event"
      ENV['hbx_ids'] = "1231 131323"
      allow(Organization).to receive(:where).with(hbx_id: "1231").and_return(organization)
      allow(Organization).to receive(:where).with(hbx_id: "131323").and_return(organization_hbx)
      allow(organization).to receive_message_chain("first.employer_profile") { employer_profile }
      allow(organization_hbx).to receive_message_chain("first.employer_profile") { employer_profile }
      Rake::Task['notice:shop_employer_notice_event'].invoke
      expect(ActiveJob::Base.queue_adapter.enqueued_jobs.count).to eq 2
      expect($stdout.string).to match(/Notice Triggered Successfully/)
    end

    it "should not trigger notice" do
      ENV['event'] = nil
      Rake::Task['notice:shop_employer_notice_event'].invoke(event: 'rspec-event', hbx_ids: '1231 131323')
      expect($stdout.string).to match(/Please specify the type of event name/)
    end

    it "only once when fein and hbx_id is given" do
      ENV['event'] = "rspec-event"
      ENV['feins'] = "123123"
      ENV['hbx_ids'] = "1231"
      allow(Organization).to receive(:where).with(hbx_id: "1231").and_return(organization)
      allow(organization).to receive_message_chain("first.employer_profile") { employer_profile }
      Rake::Task['notice:shop_employer_notice_event'].invoke(feins: "123123", hbx_ids: "1231", event: "rspec-event")
      expect(ActiveJob::Base.queue_adapter.enqueued_jobs.count).to eq 1
    end

    it "should trigger when one employer_id is given" do
      ENV['event'] = "rspec-event"
      ENV['employer_ids'] = "987"
      allow(EmployerProfile).to receive(:find).with("987").and_return(employer_profile)
      Rake::Task['notice:shop_employer_notice_event'].invoke(employer_ids: "987", event: "rpsec-event")
      expect(ActiveJob::Base.queue_adapter.enqueued_jobs.count).to eq 1
    end
  end

end
