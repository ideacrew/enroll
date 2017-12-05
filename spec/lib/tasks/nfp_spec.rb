require 'rails_helper'
Rake.application.rake_require "tasks/nfp"
include ActiveJob::TestHelper
Rake::Task.define_task(:environment)

RSpec.describe 'upload the invoice to s3 and trigger the notice', :type => :task do

  let!(:employer_profile) { FactoryGirl.create(:employer_with_renewing_planyear, start_on: TimeKeeper.date_of_record.next_month.beginning_of_month, renewal_plan_year_state: 'renewing_enrolling') }
  # let!(:employer_profile) { FactoryGirl.create(:employer_with_planyear) }
  let!(:organization) { FactoryGirl.create(:organization, employer_profile: employer_profile, hbx_id: "210504") }
  let!(:file_path) { "#{Rails.root}/spec/test_data/invoices/Dec-2017/210504_12212017_INVOICE_R.pdf"}
  let!(:params) { { recipient: employer_profile, event_object: employer_profile.active_plan_year, notice_event: "employer_invoice_available"} }

  context "Upload the notice to s3 and trigger the notice " do
    it "file invoice file exists it should upload and trigger notice" do
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(2017,12,23))
      allow(Organization).to receive(:upload_invoice).with(file_path, "210504_12212017_INVOICE_R.pdf").and_return nil
      expect_any_instance_of(Observers::Observer).to receive(:trigger_notice).with(params).and_return(true)
      Rake::Task['nfp:invoice_upload'].invoke
    end
  end
end
