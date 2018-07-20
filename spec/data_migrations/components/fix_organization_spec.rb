require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "components", "fix_organization")

describe FixOrganization, dbclean: :after_each do
  let(:given_task_name) { "fix_organization" }
  subject { FixOrganization.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update the fein of an Employer" do
    let(:employer_organization)  { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_organization_2)  { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:site)  { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    before(:each) do
      ENV["action"] = "update_fein"
      ENV["organization_fein"] = employer_organization.fein
      ENV["correct_fein"] = "987654321"
    end
    context "updating the fein when the correct information is provided" do
        it "should change fein" do
        subject.migrate
        employer_organization.reload
        expect(employer_organization.fein).to eq "987654321"
        end
    end
    context "not updating the fein when the given fein is already assigned" do
        it "should not change fein" do
        employer_organization_2.fein=("987654321")
        employer_organization_2.save!
        subject.migrate
        employer_organization.reload
        expect(employer_organization.fein).not_to eq "987654321"
        end
    end
    context "not updating the fein when there is no organization with the fein" do
        it "should not change fein" do
        employer_organization.fein=("111111111")
        employer_organization.save!
        subject.migrate
        employer_organization.reload
        expect(employer_organization.fein).not_to eq "987654321"
        end
    end
    context "not updating the fein when there is no organization with the fein" do
        it "should not change fein" do
        employer_organization.fein=("111111111")
        employer_organization.save!
        subject.migrate
        employer_organization.reload
        expect(employer_organization.fein).not_to eq "987654321"
        end
    end
    context "not updating the fein when there is no organization with the fein" do
        it "should not change fein" do
        ENV["action"]= "some_other_action" 
        subject.migrate
        employer_organization.reload
        expect(employer_organization.fein).not_to eq "987654321"
        end
    end
  end
end