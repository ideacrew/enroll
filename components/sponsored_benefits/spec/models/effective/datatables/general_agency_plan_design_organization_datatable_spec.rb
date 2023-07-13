# frozen_string_literal: true

require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

RSpec.describe Effective::Datatables::GeneralAgencyPlanDesignOrganizationDatatable, dbclean: :after_each do
  include_context "set up broker agency profile for BQT, by using configuration settings"

  describe '#authorized?' do
    context 'for current user with general agency staff role' do
      let!(:ga_profile_id) { general_agency_profile.id }
      let!(:general_agency_staff_role) do
        person.general_agency_staff_roles << ::GeneralAgencyStaffRole.new(benefit_sponsors_general_agency_profile_id: ga_profile_id, aasm_state: 'active', npn: '1234567')
        person.save!
        person.general_agency_staff_roles.first
      end
      let!(:person) { FactoryBot.create(:person) }
      let!(:user_with_ga_staff_role) { FactoryBot.create(:user, person: person, roles: ["general_agency_staff"])}

      context 'when staff belongs to agency' do
        let!(:subject) { described_class.new(profile_id: ga_profile_id) }

        it 'allows access' do
          expect(subject.authorized?(user_with_ga_staff_role, nil, nil, nil)).to eq(true)
        end
      end

      context 'when staff does not belongs to agency' do
        let!(:subject) { described_class.new(profile_id: BSON::ObjectId.new) }

        it 'denies access' do
          expect(subject.authorized?(user_with_ga_staff_role, nil, nil, nil)).to eq(false)
        end
      end
    end
  end
end
