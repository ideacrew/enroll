require "rails_helper"

RSpec.describe EmployerInvoice, dbclean: :after_each do
  let!(:conversion_employer_organization) { FactoryBot.create(:organization, :conversion_employer_with_expired_and_active_plan_years) }
  let!(:initial_employer_organization) { FactoryBot.create(:organization, :with_expired_and_active_plan_years) }
  let!(:params_regular) { {recipient: initial_employer_organization.employer_profile, event_object: initial_employer_organization.employer_profile.active_plan_year, notice_event: "initial_employer_invoice_available"} }
  let!(:params_conversion) { {recipient: conversion_employer_organization.employer_profile, event_object: conversion_employer_organization.employer_profile.active_plan_year, notice_event: "initial_employer_invoice_available"} }

  describe ".send_first_invoice_available_notice" do
    before :each do
      ActiveJob::Base.queue_adapter = :test
      ActiveJob::Base.queue_adapter.enqueued_jobs = []
    end

     context "For initial Employers" do
       subject { EmployerInvoice.new(initial_employer_organization, "Rspec_folder") }

       it "should trigger notice" do
         expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(params_regular).and_return(true)
         subject.send_first_invoice_available_notice
       end
     end

      context "For Conversion Employers" do
        subject { EmployerInvoice.new(conversion_employer_organization, "Rspec-folder") }

        it "should trigger notice for employer with initial plan year only" do
          expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(params_conversion).and_return(true)
          subject.send_first_invoice_available_notice
        end

        it "should not trigger notice for employer with renewal plan year" do
          conversion_employer_organization.employer_profile.published_plan_year.set(:aasm_state => "renewing_draft")
          expect_any_instance_of(Observers::NoticeObserver).not_to receive(:deliver)
          subject.send_first_invoice_available_notice
        end
      end

  end
end
