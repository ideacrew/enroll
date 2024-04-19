# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Style/StringConcatenation
RSpec.describe PortalHeaderHelper, :type => :helper, dbclean: :after_each do

  describe "portal_display_name" do

    let(:signed_in?){ true }

    context "has_employer_staff_role?" do
      let(:site_key)         { EnrollRegistry[:enroll_app].setting(:site_key).item }
      let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, site_key) }
      let!(:benefit_sponsor)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let!(:employer_profile)    { benefit_sponsor.employer_profile }
      let!(:employer_staff_role){ FactoryBot.create(:employer_staff_role, aasm_state:'is_closed', :benefit_sponsor_employer_profile_id=>employer_profile.id)}
      let!(:benefit_sponsor2)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let!(:employer_profile2)    { benefit_sponsor2.employer_profile }
      let!(:employer_staff_role2){ FactoryBot.create(:employer_staff_role, aasm_state:'is_active', :benefit_sponsor_employer_profile_id=>employer_profile2.id)}
      let!(:this_person) { FactoryBot.build(:person, :employer_staff_roles => [employer_staff_role, employer_staff_role2]) }
      let!(:current_user) { FactoryBot.build(:user, :person=>this_person)}
      let!(:emp_id) {current_user.person.active_employer_staff_roles.first.benefit_sponsor_employer_profile_id}
      let!(:employee_role) { FactoryBot.build(:employee_role, person: current_user.person, employer_profile: employer_profile)}

      it "should have I'm an Employer link when user has active employer_staff_role" do
        allow(current_user).to receive(:has_employer_staff_role?).and_return true
        expect(portal_display_name(controller)).to eq "<a class=\"portal\" href=\"/benefit_sponsors/profiles/employers/employer_profiles/" + emp_id.to_s + "?tab=home\"><img src=\"/images/icons/icon-business-owner.png\" />   I'm an Employer</a>"
      end

      it "should have I'm an Employee link when user has active employee_staff_role" do
        allow(current_user.person).to receive(:active_employee_roles).and_return [employee_role]
        expect(portal_display_name('')).to eq "<a class=\"portal\" href=\"/families/home\"><img src=\"/images/icons/#{site_key}-icon-individual.png\" />   I'm an Employee</a>"
      end

      it "should have Welcome prompt when user has no active role" do
        allow(current_user).to receive(:has_employer_staff_role?).and_return(false)
        expect(portal_display_name(controller)).to eq "<a class=\"portal\">#{EnrollRegistry[:enroll_app].setting(:byline).item}</a>"
      end

      context "user with active employer staff roles && employee roles" do
        before(:each) do
          allow(current_user.person).to receive(:active_employee_roles).and_return [employee_role]
          allow(current_user.person).to receive(:active_employer_staff_roles).and_return [employer_staff_role]
        end

        it "should have I'm an Employer link when user switches to Employer account" do
          emp_id = employer_staff_role.benefit_sponsor_employer_profile_id
          allow(controller).to receive(:controller_path).and_return("employers")
          url_path = "<a class=\"portal\" href=\"/benefit_sponsors/profiles/employers/employer_profiles/" + emp_id.to_s + "?tab=home\"><img src=\"/images/icons/icon-business-owner.png\" />   I'm an Employer</a>"
          expect(portal_display_name(controller)).to eq url_path
        end

        it "should have I'm an Employee link when user switches to Employee account" do
          allow(controller).to receive(:controller_path).and_return("insured")
          expect(portal_display_name(controller)).to eq "<a class=\"portal\" href=\"/families/home\"><img src=\"/images/icons/#{EnrollRegistry[:enroll_app].settings(:site_key).item}-icon-individual.png\" />   I'm an Employee</a>"
        end
      end
    end

    context "has_consumer_role?" do
      let(:current_user) { FactoryBot.build(:user, :identity_verified_date => Time.now)}
      before(:each) do
        allow(current_user).to receive(:has_consumer_role?).and_return(true)
        allow(controller).to receive(:controller_path).and_return("insured")
      end

      it "should have Individual and Family link when user completes RIDP and Consent form" do
        expect(portal_display_name(controller)).to eq "<a class=\"portal\" href=\"/families/home\"><img src=\"/images/icons/icon-family.png\" />   Individual and Family</a>"
      end

      it "should not have Individual and Family link for users with no identity_verified_date" do
        current_user.identity_verified_date = nil
        current_user.save
        expect(portal_display_name(controller)).to eq "<a class=\"portal\"><img src=\"/images/icons/icon-family.png\" />   Individual and Family</a>"
      end
    end

    context "has_general_agency_staff_role?" do
      let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let!(:benefit_sponsor)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, :with_site) }
      let!(:general_agency_profile)    { benefit_sponsor.general_agency_profile }
      let!(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, aasm_state: 'active', person: person)}
      let!(:person) { FactoryBot.build(:person, user: current_user) }
      let!(:current_user) { FactoryBot.build(:user)}

      before(:each) do
        allow(controller).to receive(:controller_path).and_return("general_agencies")
      end

      it "should have I'm a General Agency link when user has active employer_staff_role" do
        expect(portal_display_name(controller)).to eq(
          "<a class=\"portal\" href=\"/benefit_sponsors/profiles/general_agencies/general_agency_profiles/" + general_agency_profile.id.to_s + "\"><img src=\"/images/icons/icon-expert.png\" />   I'm a General Agency</a>"
        )
      end

      it "should have Welcome prompt when user has no active role" do
        allow(current_user).to receive(:has_general_agency_staff_role?).and_return(false)
        expect(portal_display_name(controller)).to eq "<a class=\"portal\">#{EnrollRegistry[:enroll_app].setting(:byline).item}</a>"
      end
    end

  end

  describe '#display_i_am_broker_for_consumer?' do
    let(:site) do
      FactoryBot.create(
        :benefit_sponsors_site,
        :with_benefit_market,
        :as_hbx_profile,
        site_key: ::EnrollRegistry[:enroll_app].settings(:site_key).item
      )
    end

    let(:broker_agency_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
    let(:broker_agency_profile) { broker_agency_organization.broker_agency_profile }
    let(:broker_agency_id) { broker_agency_profile.id }

    let(:broker_agency_organization2) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
    let(:broker_agency_profile2) { broker_agency_organization2.broker_agency_profile }

    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, :with_broker_role) }
    let(:broker_role) { person.broker_role }

    let(:broker_agency_staff_role) do
      person.create_broker_agency_staff_role(
        benefit_sponsors_broker_agency_profile_id: broker_agency_id
      )
    end

    before :each do
      allow(EnrollRegistry).to receive(:feature_enabled?).and_call_original
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:broker_role_consumer_enhancement).and_return(true)
    end

    context 'resource registry feature is enabled and person has an active consumer role' do
      context 'when:
        - person has an active consumer role
        - person does not have a broker role' do

        let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }

        it 'returns false' do
          expect(helper.display_i_am_broker_for_consumer?(person)).to eq(false)
        end
      end

      context 'when:
        - person has an active consumer role
        - person has a broker role
        - person does not have an active broker role' do

        it 'returns false' do
          expect(helper.display_i_am_broker_for_consumer?(person)).to eq(false)
        end
      end

      context 'when:
        - person has an active consumer role
        - person has a broker role
        - broker_role is a primary broker for an agency
        - person has an active broker role
        - person does not have broker_agency_staff_role' do

        before do
          broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_id)
          broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id)
          broker_role.approve!
        end

        it 'returns false' do
          expect(helper.display_i_am_broker_for_consumer?(person)).to eq(false)
        end
      end

      context 'when:
        - person has an active consumer role
        - person has a broker role
        - broker_role is a primary broker for an agency
        - person has an active broker role
        - person has a broker_agency_staff_role
        - person does not have an active broker_agency_staff_role' do

        let(:broker_agency_id) { broker_agency_profile2.id }

        before do
          broker_agency_staff_role
          broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_id)
          broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id)
          broker_role.approve!
        end

        it 'returns false' do
          expect(helper.display_i_am_broker_for_consumer?(person)).to eq(false)
        end
      end

      context 'when:
        - person has an active consumer role
        - person has a broker role
        - broker_role is a primary broker for an agency
        - person has an active broker role
        - person has a broker_agency_staff_role
        - person has an active broker_agency_staff_role
        - both broker_agency_staff_role and broker_role are not linked to the same Broker Agency Profile' do

        let(:broker_agency_id) { broker_agency_profile.id }

        before do
          broker_agency_staff_role.broker_agency_accept!
          broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_profile2.id)
          broker_agency_profile2.update_attributes!(primary_broker_role_id: broker_role.id)
          broker_role.approve!
        end

        it 'returns false' do
          expect(helper.display_i_am_broker_for_consumer?(person)).to eq(false)
        end
      end

      context 'when:
        - person has an active consumer role
        - person has a broker role
        - broker_role is a primary broker for an agency
        - person has an active broker role
        - person has a broker_agency_staff_role
        - person does not have a matching active broker_agency_staff_role
        - both broker_agency_staff_role and broker_role are linked to the same Broker Agency Profile' do

        before do
          broker_agency_staff_role
          broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_id)
          broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id)
          broker_role.approve!
        end

        it 'returns false' do
          expect(helper.display_i_am_broker_for_consumer?(person)).to eq(false)
        end
      end

      context 'when:
        - person has an active consumer role
        - person has a broker role
        - broker_role is a primary broker for an agency
        - person has an active broker role
        - person has a broker_agency_staff_role
        - person has an active broker_agency_staff_role
        - both broker_agency_staff_role and broker_role are linked to the same Broker Agency Profile' do

        before do
          broker_agency_staff_role.broker_agency_accept!
          broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_id)
          broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id)
          broker_role.approve!
        end

        it 'returns true' do
          expect(helper.display_i_am_broker_for_consumer?(person)).to eq(true)
        end
      end
    end
  end

  describe "#get_broker_profile_path" do
    let(:user) { FactoryBot.create(:user) }
    let(:person) { FactoryBot.create(:person, user: user) }
    let(:broker_role) { FactoryBot.create(:broker_role, person: person) }
    let(:broker_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(person).to receive(:broker_role).and_return(broker_role)
      allow(person).to receive(:active_broker_staff_roles).and_return([])
    end

    context "when user has an associated broker role with a valid broker agency profile" do
      before do
        broker_role.broker_agency_profile = broker_agency_profile
        allow(broker_agency_profile).to receive(:is_a?).with(BenefitSponsors::Organizations::BrokerAgencyProfile).and_return(true)
      end

      it "returns the correct path for the broker agency profile" do
        expected_path = "/path_to_broker_agency_profile/#{broker_role.benefit_sponsors_broker_agency_profile_id}"
        allow(helper).to receive(:benefit_sponsors).and_return(double(profiles_broker_agencies_broker_agency_profile_path: expected_path))
        expect(helper.get_broker_profile_path).to eq(expected_path)
      end
    end

    context "when user's broker role does not have an associated broker agency profile" do
      before do
        broker_role.broker_agency_profile = nil
      end

      it "returns nil" do
        expect(helper.get_broker_profile_path).to be_nil
      end
    end

    context "when user does not have a broker role" do
      before do
        allow(person).to receive(:broker_role).and_return(nil)
      end

      it "returns nil" do
        expect(helper.get_broker_profile_path).to be_nil
      end
    end

    context "when user has an active broker agency staff role" do
      let(:site) do
        FactoryBot.create(
          :benefit_sponsors_site,
          :with_benefit_market,
          :as_hbx_profile,
          site_key: ::EnrollRegistry[:enroll_app].settings(:site_key).item
        )
      end

      let(:broker_agency_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
      let(:broker_agency_profile) { broker_agency_organization.broker_agency_profile }
      let(:broker_agency_id) { broker_agency_profile.id }
      let(:broker_staff_role) do
        person.create_broker_agency_staff_role(
          benefit_sponsors_broker_agency_profile_id: broker_agency_id
        )
      end

      before do
        allow(person).to receive(:broker_role).and_return(nil)
        allow(person).to receive(:active_broker_staff_roles).and_return([broker_staff_role])
        broker_staff_role.broker_agency_profile = broker_agency_profile
        allow(broker_agency_profile).to receive(:is_a?).with(BenefitSponsors::Organizations::BrokerAgencyProfile).and_return(true)
      end

      it "returns the correct path for the first active broker staff role's broker agency profile" do
        expected_path = "/path_to_broker_agency_profile/#{broker_staff_role.benefit_sponsors_broker_agency_profile_id}"
        allow(helper).to receive(:benefit_sponsors).and_return(double(profiles_broker_agencies_broker_agency_profile_path: expected_path))
        expect(helper.get_broker_profile_path).to eq(expected_path)
      end
    end
  end
end
# rubocop:enable Style/StringConcatenation
