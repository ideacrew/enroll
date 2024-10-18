require 'rails_helper'

RSpec.describe "hbx_admin/_edit_aptc_csr", :dbclean => :after_each do

  let(:site) do
    FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca)
  end
  let(:organization) do
    FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site).tap do |org|
      benefit_sponsorship = org.employer_profile.add_benefit_sponsorship
      benefit_sponsorship.save
      org
    end
  end
  let(:person) do
    FactoryBot.create(:person, :with_hbx_staff_role).tap do |person|
      FactoryBot.create(:permission, :super_admin).tap do |permission|
        person.hbx_staff_role.update_attributes(permission_id: permission.id)
        person
      end
    end
  end
  let(:user) do
    FactoryBot.create(:user, person: person)
  end
  let(:benefit_sponsorship) do
    organization.benefit_sponsorships.first
  end
  let(:new_invalid_fein) { "234-839" }
  let(:org_params) {
    { "organizations_general_organization" => { "new_fein" => new_invalid_fein }
    }
  }
  let(:error_messages) {
    ["FEIN must be at least 9 digits"]
  }

  before :each do
    assign :organization, organization
    assign :errors_on_save, error_messages
  end

  context "change fein" do
    it "Should match text Change FEIN" do
      render partial: 'exchanges/hbx_profiles/edit_fein.html.erb', locals: {params: org_params}
      expect(rendered).to match(/Change FEIN/)
    end
    it "Should match text New FEIN :" do
      render partial: 'exchanges/hbx_profiles/edit_fein.html.erb', locals: {params: org_params}
      expect(rendered).to match(/New FEIN :/)
    end
    it "Should display the error: FEIN must be at least 9 digits" do
      render partial: 'exchanges/hbx_profiles/edit_fein.html.erb', locals: {params: org_params }
      expect(rendered).to match(/FEIN must be at least 9 digits/)
    end
  end

end
