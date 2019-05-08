# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

class ApplicationHelperModStubber
  extend ::BenefitSponsors::Employers::EmployerHelper
end

RSpec.describe "benefit_sponsors/profiles/registrations/edit", :type => :view, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"

  let!(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site)}
  let(:employer_profile) { organization.employer_profile }
  let!(:active_employer_staff_role) {FactoryBot.create(:benefit_sponsor_employer_staff_role, aasm_state: 'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
  let(:user) { FactoryBot.create(:user) }
  let(:agency) { BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.for_edit(profile_id: employer_profile.id.to_s) }

  before :each do
    view.extend Pundit
    view.extend BenefitSponsors::Engine.routes.url_helpers
    view.extend BenefitSponsors::Employers::EmployerHelper
    view.extend BenefitSponsors::ApplicationHelper
    view.extend BenefitSponsors::RegistrationHelper
    allow(view).to receive(:total_active_census_employees).with(employer_profile.id).and_return 0
    assign(:agency, agency)
    sign_in user
    render template: "benefit_sponsors/profiles/registrations/edit"
  end

  it "should display county based on exchange" do
    if Settings.aca.address_query_county
      expect(rendered).to have_selector('county-select')
    else
      expect(rendered).to_not have_selector('county-select')
    end
  end

  it "should display SIC code and tool tip based on exchange" do
    if ApplicationHelperModStubber.display_sic_field_for_employer?
      expect(rendered).to have_selector('#agency_organization_profile_attributes_sic_code')
      expect(rendered).to have_selector('#sicHelperToggle')
    else
      expect(rendered).to_not have_selector('#agency_organization_profile_attributes_sic_code')
      expect(rendered).to_not have_selector('#sicHelperToggle')
    end
  end
end
