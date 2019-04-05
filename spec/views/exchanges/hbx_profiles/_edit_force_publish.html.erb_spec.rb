require 'rails_helper'
RSpec.describe "/hbx_profiles/_edit_force_publish", :dbclean => :around_each do
  let(:site) do
    FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca)
  end
  let(:organization) do
    FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, :with_aca_shop_cca_employer_profile_initial_application, site: site)
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
  let(:params) { {id: benefit_sponsorship.id.to_s, employer_actions_id: "employer_actions_#{organization.employer_profile.id.to_s}" } }

  before :each do
    assign :organization, organization
    assign :benefit_application, benefit_sponsorship.benefit_applications.first
    @benefit_sponsorship = benefit_sponsorship
    render partial: 'exchanges/hbx_profiles/edit_force_publish.html.erb', locals: {params: params}
  end

  context "force publish" do
    it "Should match header text Publish Application" do
      expect(rendered).to match(/Publish Application/)
    end
    it "Should match text " do
      expect(rendered).to match(/Application Type/)
      expect(rendered).to match(/Effective Date/)
      expect(rendered).to match(/OE End Date/)
      expect(rendered).to match(/Application Status/)
      expect(rendered).to match(/Submitted At/)
      expect(rendered).to match(/Last Updated At/)
    end
  end

end
