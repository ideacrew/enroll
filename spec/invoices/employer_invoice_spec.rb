require "rails_helper"

RSpec.describe EmployerInvoice, :type => :model, dbclean: :after_each do
=begin
  describe "#send_first_invoice_available_notice", dbclean: :after_each do
    let(:plan_year){ FactoryGirl.build(:plan_year, aasm_state: "enrolled") }
    let(:employer_profile){ FactoryGirl.build(:employer_profile, plan_years: [plan_year]) }
    let(:organization)  {FactoryGirl.create(:organization, employer_profile: employer_profile)}
    let(:employer_invoice) {EmployerInvoice.new(organization)}
    let(:notice_event) { "initial_employer_invoice_available" }

    it "should trigger the notice" do
      expect(employer_invoice).to receive(:send_first_invoice_available_notice)
      employer_invoice.save_and_notify_with_clean_up
    end

    it "should trigger model event" do
      expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(recipient: employer_profile, event_object: plan_year, notice_event: notice_event, notice_params: {}).and_return(true)
      employer_invoice.send_first_invoice_available_notice
    end
  end

  context "for renewal groups", dbclean: :after_each do
    let(:active_plan_year){ FactoryGirl.build(:plan_year,start_on:TimeKeeper.date_of_record.next_month.beginning_of_month - 1.year, end_on:TimeKeeper.date_of_record.end_of_month,aasm_state: "active") }
    let(:plan_year){ FactoryGirl.build(:plan_year, aasm_state: "renewing_publish_pending") }
    let(:employer_profile){ FactoryGirl.build(:employer_profile, plan_years: [active_plan_year,plan_year]) }
    let!(:organization)  {FactoryGirl.create(:organization,employer_profile:employer_profile)}
    let!(:employer_invoice) {EmployerInvoice.new(organization)}

    it "should not trigger the notice" do
      expect_any_instance_of(EmployerInvoice).not_to receive(:trigger_notice_observer)
      employer_invoice.save_and_notify_with_clean_up
    end
  end

  context "initial employers with more than one invoice", dbclean: :after_each do
    let(:organization)  {FactoryGirl.create(:organization, employer_profile: employer_profile)}
    let(:employer_profile){ FactoryGirl.build(:employer_profile, plan_years: [plan_year]) }
    let(:plan_year){ FactoryGirl.build(:plan_year, aasm_state: "enrolled") }

    let(:employer_invoice_1) {Document.new({ title: "file_name_1", date: plan_year.start_on.next_day, creator: "hbx_staff", subject: "invoice", identifier: "urn:openhbx:terms:v1:file_storage:s3:bucket:#bucket_name#key",
                             format: "file_content_type" })}
    let(:employer_invoice_2) {Document.new({ title: "file_name_2", date: plan_year.start_on.next_month ,creator: "hbx_staff", subject: "invoice", identifier: "urn:openhbx:terms:v1:file_storage:s3:bucket:#bucket_name1#key1",
                             format: "file_content_type" })}
    let(:employer_invoice) {EmployerInvoice.new(organization)}

    before do
      organization.documents << employer_invoice_2
      organization.documents << employer_invoice_1
    end

    it "should not trigger the notice" do
      expect_any_instance_of(EmployerInvoice).not_to receive(:trigger_notice_observer)
      employer_invoice.save_and_notify_with_clean_up
    end
  end
=end
end