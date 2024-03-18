# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/ModuleLength
# rubocop:disable Style/Documentation
module BenefitSponsors
  RSpec.describe Organizations::BrokerAgencyProfilePolicy  do
    let(:broker_agency_profile_id) { "BROKER AGENCY PROFILE ID" }
    let(:user) { instance_double(User, person: person) }
    let(:broker_agency_profile) { instance_double(::BenefitSponsors::Organizations::BrokerAgencyProfile, :id => broker_agency_profile_id) }
    let(:fake_broker_agency_profile) { instance_double(::BenefitSponsors::Organizations::BrokerAgencyProfile, :id => "34509823749514314") }
    let(:policy) { ::BenefitSponsors::Organizations::BrokerAgencyProfilePolicy.new(user, broker_agency_profile) }

    before do
      allow(user).to receive(:has_consumer_role?).and_return(false)
    end

    describe "given a user with no person" do
      let(:person) { nil }

      shared_examples_for "is not permitted" do |policy_type|
        it "to access #{policy_type}" do
          expect(policy.send(policy_type)).to be_falsey
        end
      end

      it_behaves_like "is not permitted", :access_to_broker_agency_profile?
      it_behaves_like "is not permitted", :redirect_signup?
      it_behaves_like "is not permitted", :set_default_ga?
      it_behaves_like "is not permitted", :new?
      it_behaves_like "is not permitted", :index?
      it_behaves_like "is not permitted", :show?
      it_behaves_like "is not permitted", :staff_index?
      it_behaves_like "is not permitted", :family_index?
      it_behaves_like "is not permitted", :family_datatable?
      it_behaves_like "is not permitted", :commission_statements?
      it_behaves_like "is not permitted", :show_commission_statement?
      it_behaves_like "is not permitted", :download_commission_statement?
      it_behaves_like "is not permitted", :general_agency_index?
      it_behaves_like "is not permitted", :messages?
      it_behaves_like "is not permitted", :inbox?
    end

    describe "given an admin" do
      let(:hbx_staff_role) { instance_double(HbxStaffRole, permission: permission) }
      let(:person) do
        instance_double(
          Person,
          hbx_staff_role: hbx_staff_role,
          broker_role: nil,
          broker_agency_staff_roles: []
        )
      end

      context "with higher-level access" do
        let(:permission) { instance_double(Permission, modify_family: true) }

        shared_examples_for "is permitted" do |policy_type|
          it "to access #{policy_type}" do
            expect(policy.send(policy_type)).to be_truthy
          end
        end

        it_behaves_like "is permitted", :access_to_broker_agency_profile?
        it_behaves_like "is permitted", :redirect_signup?
        it_behaves_like "is permitted", :set_default_ga?
        it_behaves_like "is permitted", :new?
        it_behaves_like "is permitted", :index?
        it_behaves_like "is permitted", :show?
        it_behaves_like "is permitted", :staff_index?
        it_behaves_like "is permitted", :family_index?
        it_behaves_like "is permitted", :family_datatable?
        it_behaves_like "is permitted", :commission_statements?
        it_behaves_like "is permitted", :show_commission_statement?
        it_behaves_like "is permitted", :download_commission_statement?
        it_behaves_like "is permitted", :general_agency_index?
        it_behaves_like "is permitted", :messages?
        it_behaves_like "is permitted", :inbox?
      end

      context "with insufficient access" do
        let(:permission) { instance_double(Permission, modify_family: false) }

        shared_examples_for "is not permitted" do |policy_type|
          it "to access #{policy_type}" do
            expect(policy.send(policy_type)).to be_falsey
          end
        end

        it_behaves_like "is not permitted", :access_to_broker_agency_profile?
        it_behaves_like "is not permitted", :redirect_signup?
        it_behaves_like "is not permitted", :set_default_ga?
        it_behaves_like "is not permitted", :new?
        it_behaves_like "is not permitted", :index?
        it_behaves_like "is not permitted", :show?
        it_behaves_like "is not permitted", :staff_index?
        it_behaves_like "is not permitted", :family_index?
        it_behaves_like "is not permitted", :family_datatable?
        it_behaves_like "is not permitted", :commission_statements?
        it_behaves_like "is not permitted", :show_commission_statement?
        it_behaves_like "is not permitted", :download_commission_statement?
        it_behaves_like "is not permitted", :general_agency_index?
        it_behaves_like "is not permitted", :messages?
        it_behaves_like "is not permitted", :inbox?
      end
    end

    describe "given a broker agency staff role for that profile" do
      let(:person) do
        instance_double(
          Person,
          :hbx_staff_role => nil,
          :broker_role => nil,
          :broker_agency_staff_roles => [broker_agency_staff_role]
        )
      end

      let(:broker_agency_staff_role) do
        instance_double(
          BrokerAgencyStaffRole,
          :broker_agency_profile_id => nil,
          :benefit_sponsors_broker_agency_profile_id => broker_agency_profile_id,
          :active? => true
        )
      end

      shared_examples_for "is permitted" do |policy_type|
        it "to access #{policy_type}" do
          expect(policy.send(policy_type)).to be_truthy
        end
      end

      it_behaves_like "is permitted", :access_to_broker_agency_profile?
      it_behaves_like "is permitted", :redirect_signup?
      it_behaves_like "is permitted", :set_default_ga?
      it_behaves_like "is permitted", :new?
      it_behaves_like "is permitted", :show?
      it_behaves_like "is permitted", :family_index?
      it_behaves_like "is permitted", :family_datatable?
      it_behaves_like "is permitted", :commission_statements?
      it_behaves_like "is permitted", :show_commission_statement?
      it_behaves_like "is permitted", :download_commission_statement?
      it_behaves_like "is permitted", :general_agency_index?
      it_behaves_like "is permitted", :messages?
      it_behaves_like "is permitted", :inbox?

      it "is not permitted to access :index?" do
        expect(policy.send(:index?)).to be_falsey
      end

      it "is not permitted to access :staff_index?" do
        expect(policy.send(:staff_index?)).to be_falsey
      end
    end

    # it should be noted that the :index? and :staff_index? methods are not specific to broker agency profile
    # they are omitted from the 'for a different profile' contexts because they would be redundant
    describe "given a broker agency staff role for a different profile" do
      let(:person) do
        instance_double(
          Person,
          :hbx_staff_role => nil,
          :broker_role => nil,
          :broker_agency_staff_roles => [broker_agency_staff_role]
        )
      end

      let(:broker_agency_staff_role) do
        instance_double(
          BrokerAgencyStaffRole,
          :broker_agency_profile_id => nil,
          :benefit_sponsors_broker_agency_profile_id => fake_broker_agency_profile.id,
          :active? => true
        )
      end

      shared_examples_for "is not permitted" do |policy_type|
        it "to access #{policy_type}" do
          expect(policy.send(policy_type)).to be_falsey
        end
      end

      it_behaves_like "is not permitted", :access_to_broker_agency_profile?
      it_behaves_like "is not permitted", :redirect_signup?
      it_behaves_like "is not permitted", :set_default_ga?
      it_behaves_like "is not permitted", :new?
      it_behaves_like "is not permitted", :show?
      it_behaves_like "is not permitted", :family_index?
      it_behaves_like "is not permitted", :family_datatable?
      it_behaves_like "is not permitted", :commission_statements?
      it_behaves_like "is not permitted", :show_commission_statement?
      it_behaves_like "is not permitted", :download_commission_statement?
      it_behaves_like "is not permitted", :general_agency_index?
      it_behaves_like "is not permitted", :messages?
      it_behaves_like "is not permitted", :inbox?
    end

    describe "given a broker role for that profile" do
      let(:person) do
        instance_double(
          Person,
          :hbx_staff_role => nil,
          :broker_role => broker_role
        )
      end

      let(:broker_role) do
        instance_double(
          BrokerRole,
          :id => "SOME BROKER ID",
          :active? => true,
          :broker_agency_profile_id => nil,
          :benefit_sponsors_broker_agency_profile_id => broker_agency_profile_id
        )
      end

      shared_examples_for "is permitted" do |policy_type|
        it "to access #{policy_type}" do
          expect(policy.send(policy_type)).to be_truthy
        end
      end

      it_behaves_like "is permitted", :access_to_broker_agency_profile?
      it_behaves_like "is permitted", :redirect_signup?
      it_behaves_like "is permitted", :set_default_ga?
      it_behaves_like "is permitted", :new?
      it_behaves_like "is permitted", :show?
      it_behaves_like "is permitted", :family_index?
      it_behaves_like "is permitted", :family_datatable?
      it_behaves_like "is permitted", :commission_statements?
      it_behaves_like "is permitted", :show_commission_statement?
      it_behaves_like "is permitted", :download_commission_statement?
      it_behaves_like "is permitted", :general_agency_index?
      it_behaves_like "is permitted", :messages?
      it_behaves_like "is permitted", :inbox?

      it "is not permitted to access :index?" do
        expect(policy.send(:index?)).to be_falsey
      end

      it "is not permitted to access :staff_index?" do
        expect(policy.send(:staff_index?)).to be_falsey
      end
    end

    # it should be noted that the :index? and :staff_index? methods are not specific to broker agency profile
    # they are omitted from the 'for a different profile' contexts because they would be redundant
    describe "given a broker role for a different profile" do
      let(:person) do
        instance_double(
          Person,
          :hbx_staff_role => nil,
          :broker_role => fake_broker_role,
          :broker_agency_staff_roles => []
        )
      end

      let(:broker_role) do
        instance_double(
          BrokerRole,
          :id => "SOME BROKER ID",
          :active? => true,
          :broker_agency_profile_id => nil,
          :benefit_sponsors_broker_agency_profile_id => broker_agency_profile.id
        )
      end

      let(:fake_broker_role) do
        instance_double(
          BrokerRole,
          :id => "SOME OTHER BROKER ID",
          :active? => true,
          :broker_agency_profile_id => nil,
          :benefit_sponsors_broker_agency_profile_id => fake_broker_agency_profile.id
        )
      end

      shared_examples_for "is not permitted" do |policy_type|
        it "to access #{policy_type}" do
          expect(policy.send(policy_type)).to be_falsey
        end
      end

      it_behaves_like "is not permitted", :access_to_broker_agency_profile?
      it_behaves_like "is not permitted", :redirect_signup?
      it_behaves_like "is not permitted", :set_default_ga?
      it_behaves_like "is not permitted", :new?
      it_behaves_like "is not permitted", :show?
      it_behaves_like "is not permitted", :family_index?
      it_behaves_like "is not permitted", :family_datatable?
      it_behaves_like "is not permitted", :commission_statements?
      it_behaves_like "is not permitted", :show_commission_statement?
      it_behaves_like "is not permitted", :download_commission_statement?
      it_behaves_like "is not permitted", :general_agency_index?
      it_behaves_like "is not permitted", :messages?
      it_behaves_like "is not permitted", :inbox?
    end
  end
end
# rubocop:enable Metrics/ModuleLength
# rubocop:enable Style/Documentation