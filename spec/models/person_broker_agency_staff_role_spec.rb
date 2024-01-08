# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Person, type: :model, dbclean: :after_each do
  let(:person) { FactoryBot.create(:person) }

  describe '#create_broker_agency_staff_role' do
    context 'with valid params' do
      let(:basr_params) { { benefit_sponsors_broker_agency_profile_id: BSON::ObjectId.new } }

      it 'creates a broker agency staff role' do
        expect(
          person.create_broker_agency_staff_role(basr_params)
        ).to be_a(BrokerAgencyStaffRole)
      end

      it 'creates a broker agency staff role in initial aasm_state' do
        expect(
          person.create_broker_agency_staff_role(basr_params).aasm_state
        ).to eq('broker_agency_pending')
      end
    end

    context 'with invalid params' do
      let(:basr_params) { { dummy_field: 'dummy' } }

      it 'raises an error' do
        expect do
          person.create_broker_agency_staff_role(basr_params)
        end.to raise_error(
          Mongoid::Errors::Validations, /Validation of Person failed./
        )
      end
    end
  end
end
