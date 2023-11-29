# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/ModuleLength
# rubocop:disable Style/Documentation
module BenefitSponsors
  RSpec.describe Organizations::BrokerAgencyProfilePolicy  do
    let(:broker_agency_profile_id) { "BROKER AGENCY PROFILE ID" }
    let(:user) { instance_double(User, person: person) }
    let(:broker_agency_profile) { instance_double(::BenefitSponsors::Organizations::BrokerAgencyProfile, :id => broker_agency_profile_id) }
    let(:policy) { ::BenefitSponsors::Organizations::BrokerAgencyProfilePolicy.new(user, broker_agency_profile) }

    describe "given a user with no person" do
      let(:person) { nil }

      it "can't #access_to_broker_agency_profile?" do
        expect(policy.access_to_broker_agency_profile?).to be_falsey
      end

      it "can't #redirect_signup?" do
        expect(policy.redirect_signup?).to be_falsey
      end

      it "can't #set_default_ga?" do
        expect(policy.set_default_ga?).to be_falsey
      end
    end

    describe "given an admin" do
      let(:person) { instance_double(Person, hbx_staff_role: hbx_staff_role) }
      let(:hbx_staff_role) { instance_double(HbxStaffRole) }

      it "can #access_to_broker_agency_profile?" do
        expect(policy.access_to_broker_agency_profile?).to be_truthy
      end

      it "can #redirect_signup?" do
        expect(policy.redirect_signup?).to be_truthy
      end

      it "can #set_default_ga?" do
        expect(policy.set_default_ga?).to be_truthy
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

      it "can #access_to_broker_agency_profile?" do
        expect(policy.access_to_broker_agency_profile?).to be_truthy
      end

      it "can #redirect_signup?" do
        expect(policy.redirect_signup?).to be_truthy
      end

      it "can #set_default_ga?" do
        expect(policy.set_default_ga?).to be_truthy
      end
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
          :benefit_sponsors_broker_agency_profile_id => "A DIFFERENT BROKER AGENCY PROFILE ID",
          :active? => true
        )
      end

      it "can't #access_to_broker_agency_profile?" do
        expect(policy.access_to_broker_agency_profile?).to be_falsey
      end

      it "can't #redirect_signup?" do
        expect(policy.redirect_signup?).to be_falsey
      end

      it "can't #set_default_ga?" do
        expect(policy.set_default_ga?).to be_falsey
      end
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
          active?: true,
          benefit_sponsors_broker_agency_profile_id: broker_agency_profile_id
        )
      end

      it "can #access_to_broker_agency_profile?" do
        expect(policy.access_to_broker_agency_profile?).to be_truthy
      end

      it "can #redirect_signup?" do
        expect(policy.redirect_signup?).to be_truthy
      end

      it "can #set_default_ga?" do
        expect(policy.set_default_ga?).to be_truthy
      end
    end

    describe "given a broker role for a different profile" do
      let(:person) do
        instance_double(
          Person,
          :hbx_staff_role => nil,
          :broker_role => broker_role,
          :broker_agency_staff_roles => []
        )
      end

      let(:broker_role) do
        instance_double(
          BrokerRole,
          active?: true,
          benefit_sponsors_broker_agency_profile_id: "SOME OTHER BROKER AGENCY PROFILE ID"
        )
      end

      it "can't #access_to_broker_agency_profile?" do
        expect(policy.access_to_broker_agency_profile?).to be_falsey
      end

      it "can't #redirect_signup?" do
        expect(policy.redirect_signup?).to be_falsey
      end

      it "can't #set_default_ga?" do
        expect(policy.set_default_ga?).to be_falsey
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
# rubocop:enable Style/Documentation