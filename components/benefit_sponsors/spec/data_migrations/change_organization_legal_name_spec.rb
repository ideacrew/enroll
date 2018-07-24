require "rails_helper"
require File.join(Rails.root, "components", "benefit_sponsors", "app", "data_migrations", "change_organization_legal_name")

describe ChangeOrganizationLegalName do

  let(:given_task_name) { "change_organization_legal_name" }
  subject { ChangeOrganizationLegalName.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "change the legal name of organization" do
    let!(:rating_area)                    { FactoryGirl.create_default :benefit_markets_locations_rating_area }
    let!(:service_area)                   { FactoryGirl.create_default :benefit_markets_locations_service_area }
    let!(:site)                           { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:organization)                   { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, legal_name:"Old legal name", site: site) }

    context "with a valid fein, exisiting orgniazation's update", dbclean: :after_each do

      before(:each) do
        allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
        allow(ENV).to receive(:[]).with("new_legal_name").and_return("New legal name")
      end

      it "should successfully update organization as there is only one organization with the given fein" do
        expect(organization.legal_name).to eq "Old legal name"
        subject.migrate
        organization.reload
        expect(organization.legal_name).to eq "New legal name"
      end
    end

    context "for an invalid fein", dbclean: :after_each do
      let(:dummy_fein) { (organization.fein.to_i + 2).to_s }

      before(:each) do
        allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
        allow(ENV).to receive(:[]).with("new_legal_name").and_return("New legal name")
      end

      it "should exit as there is no organization for the given fein" do
        subject.migrate
        expect(organization.legal_name).to eq "Old legal name"
      end
    end
  end
end
