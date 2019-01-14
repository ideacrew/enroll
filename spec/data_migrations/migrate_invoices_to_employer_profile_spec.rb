require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "migrate_invoices_to_employer_profile")

describe MigrateInvoicesToEmployerProfile do

  let(:given_task_name) { "migrate_invoices_to_employer_profile" }
  subject { MigrateInvoicesToEmployerProfile.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "migrate invoices from organization to employer_profile", dbclean: :after_each do
    let(:employer_profile) { FactoryBot.create(:employer_profile)}
    let(:organization)     { employer_profile.organization }

    before do
      organization.documents << Document.new(subject: "invoice")
    end

    context "should find documents on organization with subject as invoice" do
      it "move invoices to employer_profile" do
        expect(organization.documents.size).to eq 1
        expect(organization.documents.first.subject).to eq "invoice"
        subject.migrate
        organization.reload
        expect(organization.documents.size).to eq 0
      end
    end
  end
end