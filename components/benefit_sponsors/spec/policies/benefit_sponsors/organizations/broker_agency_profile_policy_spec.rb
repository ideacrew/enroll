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

    describe "given a user with no person" do
      let(:person) { nil }

      shared_examples_for "does not permit a user with no person" do |policy_type|
        it "does not permit" do
          expect(policy.send(policy_type)).to be_falsey
        end
      end

      it_behaves_like "does not permit a user with no person", :access_to_broker_agency_profile?
      it_behaves_like "does not permit a user with no person", :redirect_signup?
      it_behaves_like "does not permit a user with no person", :set_default_ga?
    end

    describe "given an admin" do
      let(:hbx_staff_role) { instance_double(HbxStaffRole) }
      let(:person) do
        instance_double(
          Person,
          hbx_staff_role: hbx_staff_role,
          broker_role: nil,
          broker_agency_staff_roles: []
        )
      end

      context "that can access a broker agency" do
        shared_examples_for "permits admins with the right permissions" do |policy_type|
          it "does permit" do
            expect(policy.send(policy_type)).to be_truthy
          end
        end

        it_behaves_like "permits admins with the right permissions", :access_to_broker_agency_profile?
        it_behaves_like "permits admins with the right permissions", :redirect_signup?
        it_behaves_like "permits admins with the right permissions", :set_default_ga?
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

      shared_examples_for "permits broker agency staff with the right permissions" do |policy_type|
        it "does permit" do
          expect(policy.send(policy_type)).to be_truthy
        end
      end

      it_behaves_like "permits broker agency staff with the right permissions", :access_to_broker_agency_profile?
      it_behaves_like "permits broker agency staff with the right permissions", :redirect_signup?
      it_behaves_like "permits broker agency staff with the right permissions", :set_default_ga?
    end

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

      shared_examples_for "does not permit agents not associated with the broker" do |policy_type|
        it "does not permit" do
          expect(policy.send(policy_type)).to be_falsey
        end
      end

      it_behaves_like "does not permit agents not associated with the broker", :access_to_broker_agency_profile?
      it_behaves_like "does not permit agents not associated with the broker", :redirect_signup?
      it_behaves_like "does not permit agents not associated with the broker", :set_default_ga?
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

      shared_examples_for "permits brokers of the agency" do |policy_type|
        it "does permit" do
          expect(policy.send(policy_type)).to be_truthy
        end
      end

      it_behaves_like "permits brokers of the agency", :access_to_broker_agency_profile?
      it_behaves_like "permits brokers of the agency", :redirect_signup?
      it_behaves_like "permits brokers of the agency", :set_default_ga?
    end

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

      shared_examples_for "does not permit brokers from a different agency" do |policy_type|
        it "does not permit" do
          expect(policy.send(policy_type)).to be_falsey
        end
      end

      it_behaves_like "does not permit brokers from a different agency", :access_to_broker_agency_profile?
      it_behaves_like "does not permit brokers from a different agency", :redirect_signup?
      it_behaves_like "does not permit brokers from a different agency", :set_default_ga?
    end
  end
end
# rubocop:enable Metrics/ModuleLength
# rubocop:enable Style/Documentation