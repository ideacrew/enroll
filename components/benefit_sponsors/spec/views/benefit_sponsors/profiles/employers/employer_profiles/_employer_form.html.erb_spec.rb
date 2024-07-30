# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

class ApplicationHelperModStubber
  extend ::BenefitSponsors::Employers::EmployerHelper
end

RSpec.describe "/benefit_sponsors/profiles/employers/employer_profiles/_employer_form", :type => :view, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include ::L10nHelper

  let!(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site)}
  let!(:general_org) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site)}
  let!(:employer_profile) {general_org.employer_profile}
  let(:user) { FactoryBot.create(:user) }
  let(:params) do
    {"organization" =>
         {"legal_name" => "ABC Corp",
          "dba" => "",
          "fein" => "987654312",
          "profile_attributes" =>
              {"id" => employer_profile.id.to_s,
               "sic_code" => "0111",
               "entity_kind" => "c_corporation",
               "office_locations_attributes" =>
                   {"0" =>
                   {"address_attributes" =>
                   {"kind" => "primary", "address_1" => "4 Privet Drive", "address_2" => "", "city" => "Washington", "state" => "DC", "zip" => "20003"},
                    "phone_attributes" => { "kind" => "work", "area_code" => "333", "number" => "111-2222", "extension" => "111" }}},
               "contact_method" => "paper_and_electronic"}},
     "profile_id" => employer_profile.id.to_s,
     "current_user_id" => BSON::ObjectId(user.id.to_s)}
  end

  let(:agency) { BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.for_update(params) }

  before :each do
    view.extend Pundit
    view.extend BenefitSponsors::Engine.routes.url_helpers
    view.extend BenefitSponsors::Employers::EmployerHelper
    view.extend BenefitSponsors::ApplicationHelper
    view.extend ::L10nHelper
    view.extend BenefitSponsors::PermissionHelper
    assign(:agency, agency)
  end

  context "with permissions" do
    let!(:super_admin_permission) { FactoryBot.create(:permission, :super_admin) }

    let!(:security_question)  { FactoryBot.create_default :security_question }

    let!(:user_with_hbx_staff_role) { FactoryBot.create(:user, :with_hbx_staff_role) }
    let!(:person) { FactoryBot.create(:person, user: user_with_hbx_staff_role)}

    let!(:site)                          { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:organization_with_hbx_profile)  { site.owner_organization }
    let!(:organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }

    let(:bap_id) { organization.broker_agency_profile.id }

    before do
      user_with_hbx_staff_role.person.build_hbx_staff_role(hbx_profile_id: organization_with_hbx_profile.hbx_profile.id)
      user_with_hbx_staff_role.person.hbx_staff_role.permission_id = super_admin_permission.id
      user_with_hbx_staff_role.person.hbx_staff_role.save!
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:aca_shop_osse_eligibility).and_return(true)
      allow(view).to receive(:pundit_allow).with(HbxProfile, :can_view_osse_eligibility?).and_return(true)
      allow(view).to receive(:employer_current_year_osse_status).and_return("Active for #{TimeKeeper.date_of_record}")

      sign_in(user_with_hbx_staff_role)
      mock_form = ActionView::Helpers::FormBuilder.new(:agency, agency, view, {})
      render template: "benefit_sponsors/profiles/employers/employer_profiles/_employer_form", locals: {f: mock_form }
    end

    it "should view the subsidies form" do
      expect(rendered).to have_content(l10n('osse_subsidy_title'))
    end

    it "should display subsidies form" do
      expect(rendered).to_not have_selector('input[value="true"][disabled="disabled"]')
    end
  end

  context "without permissions" do

    let!(:hbx_csr_tier1_user) { FactoryBot.create(:user, :with_hbx_staff_role) }
    let!(:person) { FactoryBot.create(:person, user: hbx_csr_tier1_user)}
    let!(:site)                          { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:organization_with_hbx_profile)  { site.owner_organization }
    let!(:organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
    let!(:hbx_csr_tier1_permission) { FactoryBot.create(:permission, :hbx_csr_tier1) }

    before do
      hbx_csr_tier1_user.person.build_hbx_staff_role(hbx_profile_id: organization_with_hbx_profile.hbx_profile.id)
      hbx_csr_tier1_user.person.hbx_staff_role.permission_id = hbx_csr_tier1_permission.id
      hbx_csr_tier1_user.person.hbx_staff_role.save!
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:aca_shop_osse_eligibility).and_return(true)
      allow(view).to receive(:pundit_allow).with(HbxProfile, :can_view_osse_eligibility?).and_return(true)
      allow(view).to receive(:employer_current_year_osse_status).and_return("Active for #{TimeKeeper.date_of_record}")
      sign_in(hbx_csr_tier1_user)
      mock_form = ActionView::Helpers::FormBuilder.new(:agency, agency, view, {})
      render template: "benefit_sponsors/profiles/employers/employer_profiles/_employer_form", locals: {f: mock_form }
    end

    it "should view the subsidies form" do
      expect(rendered).to have_content(l10n('osse_subsidy_title'))
    end
  end
end
