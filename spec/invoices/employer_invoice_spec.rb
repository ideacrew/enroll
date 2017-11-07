require "rails_helper"

RSpec.describe EmployerInvoice, :type => :model, dbclean: :after_each do

  describe "#send_first_invoice_available_notice", dbclean: :after_each do
    let!(:plan_year){ FactoryGirl.build(:plan_year, aasm_state: "enrolled") }
    let!(:employer_profile){ FactoryGirl.build(:employer_profile, plan_years: [plan_year]) }
    let!(:organization)  {FactoryGirl.create(:organization, employer_profile: employer_profile)}
    let!(:employer_invoice) {EmployerInvoice.new(organization)}
    it "should trigger the notice" do
      expect(employer_invoice).to receive(:send_first_invoice_available_notice)
      employer_invoice.save_and_notify_with_clean_up
    end
  end

  describe "initial employer invoice available notice", dbclean: :after_each do
    context "for renewal groups", dbclean: :after_each do
      let(:active_plan_year){ FactoryGirl.build(:plan_year,start_on:TimeKeeper.date_of_record.next_month.beginning_of_month - 1.year, end_on:TimeKeeper.date_of_record.end_of_month,aasm_state: "active") }
      let(:plan_year){ FactoryGirl.build(:plan_year, aasm_state: "renewing_publish_pending") }
      let(:employer_profile1){ FactoryGirl.build(:employer_profile, plan_years: [active_plan_year,plan_year]) }
      let!(:organization1)  {FactoryGirl.create(:organization,employer_profile:employer_profile1)}
      let!(:employer_invoice) {EmployerInvoice.new(organization1)}

      it "should not trigger the notice" do
        expect(employer_profile1).not_to receive(:trigger_notices)
        employer_invoice.save_and_notify_with_clean_up
      end
    end

    context "for initial groups", dbclean: :after_each do
      let(:plan_year){ FactoryGirl.build(:plan_year, aasm_state: "enrolling") }
      let(:employer_profile2){ FactoryGirl.build(:employer_profile, aasm_state: "binder_paid", plan_years: [plan_year]) }
      let!(:organization2)  {FactoryGirl.create(:organization, employer_profile:employer_profile2, legal_name: "Initial Employer")}
      let!(:employer_invoice) {EmployerInvoice.new(organization2)}

      it "should trigger notice for the first invoice" do
        expect(employer_profile2).to receive(:trigger_notices).with("initial_employer_first_invoice_available")
        employer_invoice.save_and_notify_with_clean_up
      end

      context "initial employers with more than one invoice", dbclean: :after_each do
        let(:employer_invoice_1) {Document.new({ title: "file_name_1", date: plan_year.start_on.next_day, creator: "hbx_staff", subject: "invoice", identifier: "urn:openhbx:terms:v1:file_storage:s3:bucket:#bucket_name#key",
                             format: "file_content_type" })}
        let(:employer_invoice_2) {Document.new({ title: "file_name_2", date: plan_year.start_on.next_month ,creator: "hbx_staff", subject: "invoice", identifier: "urn:openhbx:terms:v1:file_storage:s3:bucket:#bucket_name1#key1",
                             format: "file_content_type" })}
        let!(:employer_invoice3) {EmployerInvoice.new(organization2)}

        it "should not trigger the notice" do
          organization2.documents << employer_invoice_2
          organization2.documents << employer_invoice_1
          expect(employer_profile2).not_to receive(:trigger_notices)
          employer_invoice3.save_and_notify_with_clean_up
        end
      end
    end
  end

end