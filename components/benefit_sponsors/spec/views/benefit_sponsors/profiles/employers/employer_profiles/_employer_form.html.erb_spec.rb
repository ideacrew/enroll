# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

class ApplicationHelperModStubber
  extend ::BenefitSponsors::Employers::EmployerHelper
end

RSpec.describe "/benefit_sponsors/profiles/employers/employer_profiles/_employer_form.html.erb", :type => :view, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"

  let!(:organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site)}
  let!(:general_org) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site)}
  let!(:employer_profile) {general_org.employer_profile}
  let!(:active_employer_staff_role) {FactoryBot.create(:benefit_sponsor_employer_staff_role, aasm_state: 'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
  let(:user) { FactoryBot.create(:user) }
  let!(:hbx_profile) { FactoryBot.create(:hbx_profile) }
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
    view.extend BenefitSponsors::RegistrationHelper
    allow(view).to receive(:osse_eligibility_is_enabled?).and_return(true)
    assign(:agency, agency)
  end

  context "with permissions" do
    let!(:super_admin_user) { FactoryBot.create(:user, :with_hbx_staff_role, person: super_admin_person) }
    let!(:super_admin_permission) { FactoryBot.create(:permission, :super_admin) }
    let!(:super_admin_person) { FactoryBot.create(:person) }
    let!(:hbx_super_admin_staff_role) do
      HbxStaffRole.create!(person: super_admin_person, permission_id: super_admin_permission.id, subrole: super_admin_subrole, hbx_profile_id: hbx_profile.id)
    end
    let(:super_admin_subrole) { 'super_admin' }

    before do
      sign_in super_admin_user
      mock_form = ActionView::Helpers::FormBuilder.new(:agency, agency, view, {})
      render template: "benefit_sponsors/profiles/employers/employer_profiles/_employer_form.html.erb", locals: {f: mock_form }
    end

    it "should display subsidies form" do
      expect(rendered).to have_content(l10n('subsidies'))
    end
  end

  context "without permissions" do
    let!(:hbx_csr_tier1_user) { FactoryBot.create(:user, :with_hbx_staff_role, person: hbx_csr_tier1_person) }
    let!(:hbx_csr_tier1_permission) { FactoryBot.create(:permission, :hbx_csr_tier1) }
    let!(:hbx_csr_tier1_person) { FactoryBot.create(:person) }
    let!(:hbx_csr_tier1_role) do
      HbxStaffRole.create!(person: hbx_csr_tier1_person, permission_id: hbx_csr_tier1_permission.id, subrole: hbx_csr_tier1_subrole, hbx_profile_id: hbx_profile.id)
    end
    let(:hbx_csr_tier1_subrole) { 'hbx_csr_tier1' }

    before do
      sign_in hbx_csr_tier1_user
      mock_form = ActionView::Helpers::FormBuilder.new(:agency, agency, view, {})
      render template: "benefit_sponsors/profiles/employers/employer_profiles/_employer_form.html.erb", locals: {f: mock_form }
    end

    it "should not display subsidies form" do
      expect(rendered).to_not have_content(l10n('subsidies'))
    end
  end
end
