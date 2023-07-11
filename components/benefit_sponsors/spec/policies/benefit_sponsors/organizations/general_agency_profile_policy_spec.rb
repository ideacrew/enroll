# frozen_string_literal: true

require 'rails_helper'
# spec for GeneralAgencyProfilePolicy
module BenefitSponsors
  RSpec.describe Organizations::GeneralAgencyProfilePolicy, dbclean: :after_each  do
    let!(:user) { FactoryBot.create(:user) }
    let!(:person) {FactoryBot.create(:person, user: user)}

    context 'access to general agency profile' do
      it 'returns true if admin user and has hbx staff role' do
        user_with_hbx_staff_role = FactoryBot.create(:user, :with_hbx_staff_role)
        FactoryBot.create(:person, user: user_with_hbx_staff_role)
        policy = BenefitSponsors::Organizations::GeneralAgencyProfilePolicy.new(user_with_hbx_staff_role, nil)
        expect(policy.can_read_inbox?).to be true
      end

      it 'returns false if user has no valid role' do
        policy = BenefitSponsors::Organizations::GeneralAgencyProfilePolicy.new(user, nil)
        expect(policy.can_read_inbox?).to be false
      end

      it 'returns true if general agency has staff role' do
        person_with_ga_staff_role = FactoryBot.create(:person, :with_general_agency_staff_role)
        user_with_ga_staff_role = FactoryBot.create(:user, person: person_with_ga_staff_role, roles: ["general_agency_staff"])
        policy = BenefitSponsors::Organizations::GeneralAgencyProfilePolicy.new(user_with_ga_staff_role, nil)

        expect(policy.can_read_inbox?).to be true
      end
    end
  end

  RSpec.describe Organizations::GeneralAgencyProfilePolicy, "authorizing the viewing of families" do

    let(:general_agency_profile_id) { "SOME BOGUS ID" }
    let(:hbx_staff_user) { instance_double(User, has_hbx_staff_role?: true)}
    let(:general_agency_staff_user) { instance_double(User, has_hbx_staff_role?: false, person: general_agency_staff_person) }
    let(:normal_user) { instance_double(User, has_hbx_staff_role?: false, person: normal_person) }
    let(:general_agency) { instance_double(::BenefitSponsors::Organizations::GeneralAgencyProfile, id: general_agency_profile_id) }
    let(:general_agency_staff_role) do
      instance_double(
        GeneralAgencyStaffRole,
        {
          benefit_sponsors_general_agency_profile_id: general_agency_profile_id,
          active?: true
        }
      )
    end
    let(:normal_person) do
      instance_double(
        Person,
        general_agency_staff_roles: []
      )
    end
    let(:general_agency_staff_person) do
      instance_double(
        Person,
        general_agency_staff_roles: [general_agency_staff_role]
      )
    end

    it "allows an hbx-staff user" do
      authorized = ::BenefitSponsors::Organizations::GeneralAgencyProfilePolicy.new(hbx_staff_user, general_agency).families?
      expect(authorized).to be_truthy
    end

    it "allows a user who is active general agency staff" do
      authorized = ::BenefitSponsors::Organizations::GeneralAgencyProfilePolicy.new(general_agency_staff_user, general_agency).families?
      expect(authorized).to be_truthy
    end

    it "denies a regular user" do
      authorized = ::BenefitSponsors::Organizations::GeneralAgencyProfilePolicy.new(normal_user, general_agency).families?
      expect(authorized).to be_falsey
    end
  end
end

