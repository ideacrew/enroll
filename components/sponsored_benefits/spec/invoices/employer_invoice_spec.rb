require "rails_helper"

RSpec.describe EmployerInvoice, dbclean: :after_each do
  let!(:conversion_employer_organization) { FactoryGirl.create(:organization, :conversion_employer_with_expired_and_active_plan_years) }
  let!(:regular_employer_organization) { FactoryGirl.create(:organization, :with_expired_and_active_plan_years) }

  describe ".send_first_invoice_available_notice" do
    before :each do
      ActiveJob::Base.queue_adapter = :test
      ActiveJob::Base.queue_adapter.enqueued_jobs = []
    end

     context "Regualr Employers" do
       subject { EmployerInvoice.new(regular_employer_organization, "Rspec_folder") }

       it "should trigger notice" do
         subject.send_first_invoice_available_notice
         queued_job = fetch_job_queue
         expect(queued_job[:args]).to eq [regular_employer_organization.employer_profile.id.to_s, "initial_employer_invoice_available"]
       end
     end

      context "Conversion Employers" do
        subject { EmployerInvoice.new(conversion_employer_organization, "Rspec-folder") }

        it "should trigger notice on employer with plan year is not in renewal state" do
          subject.send_first_invoice_available_notice
          queued_job = fetch_job_queue
         expect(queued_job[:args]).to eq [conversion_employer_organization.employer_profile.id.to_s, "initial_employer_invoice_available"]
        end

        it "should not trigger notice on employer with plan year is in renewal state" do
          conversion_employer_organization.employer_profile.published_plan_year.update_attributes!(:aasm_state => "renewing_draft")
          subject.send_first_invoice_available_notice
          queued_job = fetch_job_queue
          expect(queued_job).to eq nil
        end
      end

    def fetch_job_queue
      ActiveJob::Base.queue_adapter.enqueued_jobs.find do |job_info|
        job_info[:job] == ShopNoticesNotifierJob
      end
    end

  end
end
