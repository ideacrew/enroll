require 'rails_helper'
Rake.application.rake_require "tasks/notices/shop_employer_notice_for_all_inputs"
include ActiveJob::TestHelper
Rake::Task.define_task(:environment)

RSpec.describe 'Generate notices to employer by taking hbx_ids, feins, employer_ids and event name', :type => :task do
  let!(:employer_profile) { double(:employer_profile, id: "rspec-id" ) }
  let!(:organization) { double(:organization, employer_profile: employer_profile, hbx_id: "1231") }
  let!(:organization_hbx) { double(:organization, employer_profile: employer_profile,  hbx_id: "131323") }
  let!(:organization_feins) { double(:organization,  employer_profile: employer_profile, fein: "987") }

  before :each do
    $stdout = StringIO.new
   ActiveJob::Base.queue_adapter = :test
  end

  after(:all) do
    $stdout = STDOUT
  end

  context "should not Trigger notice" do
    it "When event name is not specified" do
      ENV['event'] = nil
      ENV['employer_ids'] = employer_profile.id
      allow(EmployerProfile).to receive(:find).with(employer_profile.id).and_return(employer_profile)
      Rake::Task["notice:shop_employer_notice_event"].invoke
      expect($stdout.string).to match(/Please specify the type of event name/)

      # expect(ActiveJob::Base.queue_adapter.enqueued_jobs.count).to eq 1
      # expect {
      #   ShopNoticesNotifierJob.perform_later("rspec-id","rspec-event")
      # }.to have_enqueued_job
    end
  end

  context "Trigger Notice for 2 employers" do
    it "when multiple hbx_ids input is given" do
      ENV['event'] = "rspec-event"
      ENV['hbx_ids'] = "1231 131323"
      allow(Organization).to receive(:where).with(hbx_id: "1231").and_return(organization)
      allow(Organization).to receive(:where).with(hbx_id: "131323").and_return(organization_hbx)
      allow(organization).to receive_message_chain("first.employer_profile") { employer_profile }
      allow(organization_hbx).to receive_message_chain("first.employer_profile") { employer_profile }
      Rake::Task["notice:shop_employer_notice_event"].invoke
      expect(ActiveJob::Base.queue_adapter.enqueued_jobs.count).to eq 2
    end
  end

  context "Trigger Notice" do
    it "When organization fein is given" do
      ENV['event'] = "rspec-event"
      ENV['feins'] = "987"
      allow(Organization).to receive(:where).with(fein: "987").and_return(organization_feins)
      allow(organization_feins).to receive_message_chain("first.employer_profile") { employer_profile }
      Rake::Task["notice:shop_employer_notice_event"].invoke
      expect(ActiveJob::Base.queue_adapter.enqueued_jobs.count).to eq 1
    end
  end

  context " Trigger Notice " do
    it "only once when fein and hbx_id is given" do
      ENV['event'] = "rspec-event"
      ENV['feins'] = "123123"
      ENV['hbx_ids'] = "1231"
      allow(Organization).to receive(:where).with(hbx_id: "1231").and_return(organization)
      allow(organization).to receive_message_chain("first.employer_profile") { employer_profile }
      Rake::Task["notice:shop_employer_notice_event"].invoke
      expect(ActiveJob::Base.queue_adapter.enqueued_jobs.count).to eq 1
    end
  end
  end
