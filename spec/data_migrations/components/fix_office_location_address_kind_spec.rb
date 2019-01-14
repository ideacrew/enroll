require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "components", "fix_office_location_address_kind")

describe FixOfficeLocationAddressKind, dbclean: :after_each do
  let(:given_task_name) { "fix_office_location_address_kind" }
  subject { FixOfficeLocationAddressKind.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update employer primary office location address kind" do

    let(:employer_organization)   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)        { employer_organization.employer_profile }
    let(:site)                    { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }

    context "when employer primary office address is work should update kind to primary " do

      it "should change effective on date" do
        expect(employer_profile.primary_office_location.address.kind).to eq "work"
        subject.migrate
        employer_profile.reload
        expect(employer_profile.primary_office_location.address.kind).to eq "primary"
      end
    end
  end
end
