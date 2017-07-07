require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_organization_legal_name")

describe ChangeOrganizationLegalName do

  let(:given_task_name) { "change_organization_legal_name" }
  subject { ChangeOrganizationLegalName.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "change the legal name of organization" do
    let(:organization) { FactoryGirl.create(:organization,legal_name:"Old legal name")}
    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
      allow(ENV).to receive(:[]).with("new_legal_name").and_return("New legal name")
    end
    context "change the orgniazation legal name", dbclean: :after_each do
      it "change the organization with the given legal name" do
        expect(organization.legal_name).to eq "Old legal name"
        subject.migrate
        organization.reload
        expect(organization.legal_name).to eq "New legal name"
      end
    end
  end
end
