require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "delete_single_invoice_with_fein")

require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe DeleteSingleInvoiceWithFein, dbclean: :after_each do
  let(:given_task_name) { "delete_single_invoice_with_fein" }
  subject { ::DeleteSingleInvoiceWithFein.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "deletes the invoice" do

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let!(:organization) { abc_organization }
    let!(:employer_profile) { organization.employer_profile }
    let(:employer_invoice_1) { ::BenefitSponsors::Documents::Document.new({ title: "file_name_1", date: TimeKeeper.date_of_record, creator: "hbx_staff", subject: "initial_invoice", identifier: "urn:openhbx:terms:v1:file_storage:s3:bucket:#bucket_name#key",
        format: "file_content_type" })}

    before do
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
      employer_profile.documents << employer_invoice_1
      allow(ENV).to receive(:[]).with("date").and_return(employer_profile.documents.first.date.to_s)
    end

    it "Should delete the invoice" do
      expect(organization.employer_profile.documents.size).to eq 1
      subject.migrate
      organization.employer_profile.reload
      expect(organization.employer_profile.documents.size).to eq 0
    end
  end
end

