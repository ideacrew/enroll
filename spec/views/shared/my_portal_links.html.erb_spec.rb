# frozen_string_literal: true

require 'rails_helper'

describe 'shared/_my_portal_links.html.erb', dbclean: :after_each do
  let(:brce_enabled_or_disabled) { false }
  let(:families_home_url) { '/families/home?tab=home' }

  before :each do
    allow(EnrollRegistry).to receive(:feature_enabled?).and_call_original
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:broker_role_consumer_enhancement).and_return(brce_enabled_or_disabled)
  end

  context "with employee role" do
    let(:user) { FactoryBot.create(:user, person: person, roles: ["employee"]) }
    let(:person) { FactoryBot.create(:person, :with_employee_role)}

    before do
      allow(EnrollRegistry[:aca_shop_market].feature).to receive(:is_enabled).and_return(true)
    end

    it "should have one portal link" do
      all_census_ee = FactoryBot.create(:census_employee)
      all_er_profile = all_census_ee.employer_profile
      person.employee_roles.first.census_employee = all_census_ee
      person.employee_roles.first.save!
      sign_in(user)
      render 'shared/my_portal_links'
      expect(rendered).to have_link('My Insured Portal', href: families_home_url)
      expect(rendered).to_not have_selector('dropdownMenu1')
    end
  end

  context "with employer role & employee role" do
    let(:general_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_site, :with_aca_shop_cca_employer_profile) }
    let(:employer_profile)    { general_organization.employer_profile }
    let(:benefit_sponsorship) { employer_profile.add_benefit_sponsorship }
    let(:active_employer_staff_role) {FactoryBot.create(:benefit_sponsor_employer_staff_role, aasm_state:'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
    let(:user) { FactoryBot.create(:user, person: person, roles: ["employee", "employer_staff"]) }
    let(:person) { FactoryBot.create(:person, :with_employee_role, :with_employer_staff_role)}
    let!(:employee_role) { FactoryBot.create(:employee_role, person: person)}
    let(:census_employee) {FactoryBot.create(:benefit_sponsors_census_employee, employer_profile: employer_profile, employee_role_id: employee_role.id)}

    before do
      allow(EnrollRegistry[:aca_shop_market].feature).to receive(:is_enabled).and_return(true)
    end

    it "should have one portal links and popover" do
      allow(employer_profile).to receive(:active_benefit_sponsorship).and_return(benefit_sponsorship)
      employer_profile.reload
      employee_role.new_census_employee = census_employee
      allow(user).to receive(:has_employee_role?).and_return(true)
      sign_in(user)
      render 'shared/my_portal_links'
      expect(rendered).to have_link('My Insured Portal', href: families_home_url)
      expect(rendered).to have_content(census_employee.employer_profile.legal_name)
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to match(/Insured/)
    end
  end

  context "with employer roles & employee role" do
    let(:user) { FactoryBot.create(:user, person: person, roles: ["employee", "employer_staff"]) }
    let(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:benefit_sponsor)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)    { benefit_sponsor.employer_profile }
    let(:active_employer_staff_role) {FactoryBot.create(:benefit_sponsor_employer_staff_role, aasm_state:'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
    let(:person) { FactoryBot.create(:person, :with_employee_role, employer_staff_roles:[active_employer_staff_role]) }
    let!(:employee_role) { FactoryBot.create(:employee_role, person: person)}
    let(:benefit_sponsorship)    { BenefitSponsors::BenefitSponsorships::BenefitSponsorship.new(profile: employer_profile) }

    before do
      allow(EnrollRegistry[:aca_shop_market].feature).to receive(:is_enabled).and_return(true)
    end

    it "should have one portal links and popover" do
      allow(employer_profile).to receive(:active_benefit_sponsorship).and_return(benefit_sponsorship)
      employer_profile.reload
      all_census_ee = FactoryBot.create(:benefit_sponsors_census_employee, employer_profile: employer_profile, employee_role_id: employee_role.id)
      all_er_profile = all_census_ee.employer_profile
      all_er_profile.organization.update_attributes(legal_name: 'Second Company') # not always Turner
      EmployerStaffRole.create(person:person, benefit_sponsor_employer_profile_id: all_er_profile.id)
      person.employee_roles.first.census_employee = all_census_ee
      person.employee_roles.first.save!
      sign_in(user)
      render 'shared/my_portal_links'
      expect(rendered).to have_link('My Insured Portal', href: families_home_url)
      expect(rendered).to have_content(all_er_profile.legal_name)
      expect(rendered).to have_content('Second Company')
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to match(/Insured/)
    end
  end

  context "with general agency staff role" do
    let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:benefit_sponsor)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, :with_site) }
    let!(:general_agency_profile)    { benefit_sponsor.general_agency_profile }
    let!(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, aasm_state: 'active', person: person)}
    let!(:person) { FactoryBot.create(:person) }

    let(:user) { FactoryBot.create(:user, person: person, roles: ["general_agency_staff"]) }

    it "should have one portal link" do
      allow(user).to receive(:has_general_agency_staff_role?).and_return(true)
      sign_in(user)
      render 'shared/my_portal_links'
      expect(rendered).to have_content('My General Agency Portal')
      expect(rendered).to_not have_selector('dropdownMenu1')
    end
  end

  context "with general agency staff and employer role" do
    let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:benefit_sponsor)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, :with_site) }
    let!(:general_agency_profile)    { benefit_sponsor.general_agency_profile }
    let!(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, aasm_state: 'active', person: person)}
    let!(:person) { FactoryBot.create(:person, :with_employer_staff_role) }
    let(:user) { FactoryBot.create(:user, person: person, roles: ["general_agency_staff", "employer_staff"]) }

    let(:general_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_site, :with_aca_shop_cca_employer_profile) }
    let(:employer_profile)    { general_organization.employer_profile }
    let(:benefit_sponsorship) { employer_profile.add_benefit_sponsorship }
    let(:active_employer_staff_role) {FactoryBot.create(:benefit_sponsor_employer_staff_role, aasm_state:'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}

    it "should have one portal link" do
      allow(user).to receive(:has_general_agency_staff_role?).and_return(true)
      allow(employer_profile).to receive(:active_benefit_sponsorship).and_return(benefit_sponsorship)
      employer_profile.reload
      sign_in(user)
      render 'shared/my_portal_links'
      expect(rendered).to have_content(general_agency_profile.legal_name)
      expect(rendered).to have_content(employer_profile.legal_name)
      expect(rendered).to have_selector('.dropdown-menu')
      expect(rendered).to have_selector('.dropdown-menu')
    end
  end

  describe 'with dual roles when one of the roles is consumer_role' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:user) { FactoryBot.create(:user, person: person) }
    let(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, site_key: ::EnrollRegistry[:enroll_app].settings(:site_key).item) }
    let(:broker_agency_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
    let(:broker_agency_id) { broker_agency_organization.broker_agency_profile.id }

    let(:auth_and_consent_url) { '/insured/consumer_role/ridp_agreement' }
    let(:broker_agency_registration_url) { '/benefit_sponsors/profiles/registrations/new?profile_type=broker_agency' }
    let(:broker_agency_portal_url) { "/benefit_sponsors/profiles/broker_agencies/broker_agency_profiles/#{broker_agency_id}?tab=home" }

    before do
      person.broker_agency_staff_roles.create!(
        {
          aasm_state: 'active',
          benefit_sponsors_broker_agency_profile_id: broker_agency_id
        }
      )

      allow(user).to receive(:consumer_identity_verified?).and_return(identity_verified)

      sign_in(user)
      render 'shared/my_portal_links'
    end

    context 'consumer role without RIPD' do
      let(:identity_verified) { false }

      context 'when the feature is disabled' do
        it 'does not have families home link' do
          expect(rendered).not_to have_link('My Insured Portal', href: families_home_url)
        end

        it 'has broker agency portal link' do
          expect(rendered).to have_link(
            'My Broker Agency Portal', href: broker_agency_registration_url
          )
        end
      end

      context 'when the feature is enabled' do
        let(:brce_enabled_or_disabled) { true }

        it 'does not have families home link' do
          expect(rendered).not_to have_link('My Insured Portal', href: families_home_url)
        end

        it 'has RIDP failed validation page' do
          expect(rendered).to have_link('My Insured Portal', href: auth_and_consent_url)
        end

        it 'has broker agency portal link' do
          expect(rendered).to have_link(
            broker_agency_organization.legal_name, href: broker_agency_portal_url
          )
        end
      end
    end

    context 'consumer role with RIPD' do
      let(:identity_verified) { true }

      context 'when the feature is disabled' do
        it 'does not have families home link' do
          expect(rendered).not_to have_link('My Insured Portal', href: families_home_url)
        end

        it 'has broker agency portal link' do
          expect(rendered).to have_link(
            'My Broker Agency Portal', href: broker_agency_registration_url
          )
        end
      end

      context 'when the feature is enabled' do
        let(:brce_enabled_or_disabled) { true }

        it 'has families home link' do
          expect(rendered).to have_link('My Insured Portal', href: auth_and_consent_url)
        end

        it 'has broker agency portal link' do
          expect(rendered).to have_link(
            broker_agency_organization.legal_name, href: broker_agency_portal_url
          )
        end
      end
    end
  end
end
