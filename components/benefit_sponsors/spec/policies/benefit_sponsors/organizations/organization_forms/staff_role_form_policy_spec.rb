# frozen_string_literal: true

require "rails_helper"

# spec for testing the StaffRoleFormPolicy in the BenefitSponsors engine
# rubocop:disable Metrics/ModuleLength
module BenefitSponsors
  RSpec.describe Organizations::OrganizationForms::StaffRoleFormPolicy, dbclean: :after_each  do
    # Person/User
    let!(:user)                           { FactoryBot.create(:user, :with_hbx_staff_role) }
    let!(:person)                         { FactoryBot.create(:person, user: user) }

    # Admin/Permissions
    # NOTE: permissions for broker agency are frequently subject to change, specs built out for both kinds of hbx_staff_role
    let(:super_admin_permission)         { FactoryBot.create(:permission, :super_admin) }
    let(:read_only_permission)           { FactoryBot.create(:permission, :hbx_read_only) }

    # Organizations/Profiles
    let!(:site)                           { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:broker_organization)            { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
    let(:broker_agency_profile)          { broker_organization.broker_agency_profile }
    let(:organization_with_hbx_profile)  { site.owner_organization }

    # Policy/Input
    let(:policy)                          { BenefitSponsors::Organizations::OrganizationForms::StaffRoleFormPolicy.new(user, staff_role_form) }
    let(:staff_role_form) do
      BenefitSponsors::Organizations::OrganizationForms::StaffRoleForm.new(profile_id: broker_agency_profile.id,
                                                                           profile_type: "broker_agency_staff",
                                                                           person_id: '4323563457345687',
                                                                           first_name: "steve",
                                                                           last_name: "smith",
                                                                           dob: "10/10/1974")
    end

    describe 'for a BrokerAgencyStaffRoleForm' do
      context "an hbx_admin " do

        before do
          user.person.build_hbx_staff_role(hbx_profile_id: organization_with_hbx_profile.hbx_profile.id)
          user.person.hbx_staff_role.permission_id = super_admin_permission.id
          user.person.hbx_staff_role.save!
        end

        context 'with a super_admin role' do
          shared_examples_for "is permitted" do |policy_type|
            it "to #{policy_type} a BrokerStaffAgencyRole form" do
              expect(policy.send(policy_type)).to be_truthy
            end
          end

          it_behaves_like "is permitted", :create?
          it_behaves_like "is permitted", :edit?
          it_behaves_like "is permitted", :destroy?
          it_behaves_like "is permitted", :approve?
          it_behaves_like "is permitted", :can_edit?
        end

        # NOTE: permissions for broker agency are frequently subject to change, specs built out for both kinds of hbx_staff_role
        context 'with a read-only role' do
          before do
            user.person.hbx_staff_role.permission_id = read_only_permission.id
            user.person.hbx_staff_role.save!
          end

          shared_examples_for "is permitted" do |policy_type|
            it "to #{policy_type} a BrokerStaffAgencyRole form" do
              expect(policy.send(policy_type)).to be_truthy
            end
          end

          it_behaves_like "is permitted", :create?
          it_behaves_like "is permitted", :edit?
          it_behaves_like "is permitted", :destroy?
          it_behaves_like "is permitted", :approve?
          it_behaves_like "is permitted", :can_edit?
        end
      end

      context 'as a member of a broker agency' do
        context 'a broker' do
          let!(:broker_role)                   { FactoryBot.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person) }
          let!(:broker_agency_staff_role)      { FactoryBot.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person) }

          shared_examples_for "is permitted" do |policy_type|
            it "to #{policy_type} a BrokerStaffAgencyRole form" do
              expect(policy.send(policy_type)).to be_truthy
            end
          end

          it_behaves_like "is permitted", :create?
          it_behaves_like "is permitted", :edit?
          it_behaves_like "is permitted", :destroy?
          it_behaves_like "is permitted", :approve?
          it_behaves_like "is permitted", :can_edit?
        end

        context 'an agent' do
          let!(:broker_agency_staff_role) do
            FactoryBot.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person, aasm_state: 'active')
          end

          shared_examples_for "is permitted" do |policy_type|
            it "to #{policy_type} a BrokerStaffAgencyRole form" do
              expect(policy.send(policy_type)).to be_truthy
            end
          end

          it_behaves_like "is permitted", :create?
          it_behaves_like "is permitted", :edit?
          it_behaves_like "is permitted", :destroy?
          it_behaves_like "is permitted", :approve?
          it_behaves_like "is permitted", :can_edit?
        end
      end

      context 'as a member of a different agency' do
        let!(:second_organization)           { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
        let!(:profile_2)                     { second_organization.broker_agency_profile }

        context 'a broker' do
          let!(:broker_role)                   { FactoryBot.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: profile_2.id, person: person) }
          let!(:broker_agency_staff_role)      { FactoryBot.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: profile_2.id, person: person) }

          shared_examples_for "is not permitted" do |policy_type|
            it "to #{policy_type} a BrokerStaffAgencyRole form" do
              expect(policy.send(policy_type)).to be_falsey
            end
          end

          it_behaves_like "is not permitted", :create?
          it_behaves_like "is not permitted", :edit?
          it_behaves_like "is not permitted", :destroy?
          it_behaves_like "is not permitted", :approve?
          it_behaves_like "is not permitted", :can_edit?
        end

        context 'an agent' do
          let!(:broker_agency_staff_role) do
            FactoryBot.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: profile_2.id, person: person, aasm_state: 'active')
          end

          shared_examples_for "is not permitted" do |policy_type|
            it "to #{policy_type} a BrokerStaffAgencyRole form" do
              expect(policy.send(policy_type)).to be_falsey
            end
          end

          it_behaves_like "is not permitted", :create?
          it_behaves_like "is not permitted", :edit?
          it_behaves_like "is not permitted", :destroy?
          it_behaves_like "is not permitted", :approve?
          it_behaves_like "is not permitted", :can_edit?
        end
      end

      context 'as a user with no person' do
        let(:make_person_nil)  { user.update(person: nil) }

        shared_examples_for "is not permitted" do |policy_type|
          it "to #{policy_type} a BrokerStaffAgencyRole form" do
            expect(policy.send(policy_type)).to be_falsey
          end
        end

        it_behaves_like "is not permitted", :create?
        it_behaves_like "is not permitted", :edit?
        it_behaves_like "is not permitted", :destroy?
        it_behaves_like "is not permitted", :approve?
        it_behaves_like "is not permitted", :can_edit?
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
