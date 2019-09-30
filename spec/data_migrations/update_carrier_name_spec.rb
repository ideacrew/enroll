require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_carrier_name")

describe UpdateCarrierName, dbclean: :after_each do

  let(:given_task_name) { "update_carrier_name" }
  subject { UpdateCarrierName.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update carrier legal name" do
    let(:carrier_profile)  { FactoryBot.create(:carrier_profile, hbx_carrier_id: "111222")}
    let(:new_legal_name) { "New Legal Name" }

    it "allow dependent ssn's to be updated to nil" do
      organization = carrier_profile.organization
      ClimateControl.modify hbx_id: carrier_profile.hbx_carrier_id.to_s, name: new_legal_name do
        subject.migrate
      end
      organization.reload
      expect(organization.legal_name).to match(new_legal_name)
    end
  end

  describe "update carrier legal name in exempt_organization" do
    let(:site) { build(:benefit_sponsors_site, :with_owner_exempt_organization, Settings.site.key) }
    let(:issuer_profile) { create(:benefit_sponsors_organizations_issuer_profile, organization: site.owner_organization, hbx_carrier_id: "111222") }

    # let(:exempt_organization) { FactoryBot.create(:benefit_sponsors_organizations_exempt_organization, :with_issuer_profile)}
    let(:new_legal_name) { "New Legal Name" }

    it "allow dependent ssn's to be updated to nil" do
      # exempt_organization = issuer_profile.exempt_organization
      ClimateControl.modify hbx_id: issuer_profile.hbx_carrier_id.to_s, name: new_legal_name do
        subject.migrate
      end
      issuer_profile.organization.reload
      expect(issuer_profile.organization.legal_name).to match(new_legal_name)
    end
  end
end
