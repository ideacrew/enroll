# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Operations::Locations::Addresses::Destroy, dbclean: :after_each do

  let(:primary) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: primary) }
  let(:primary_member) { family.primary_applicant }

  let(:application) do
    FactoryBot.create(:financial_assistance_application, family_id: family.id, aasm_state: application_aasm_state)
  end

  let(:applicant) do
    FactoryBot.create(
      :financial_assistance_applicant,
      :with_home_address,
      application: application,
      is_primary_applicant: true,
      family_member_id: primary_member.id,
      person_hbx_id: primary.hbx_id
    )
  end

  let(:address) do
    applicant.addresses.create(
      kind: address_kind,
      address_1: '1234 Awesome Street NE',
      city: 'Washington',
      state: EnrollRegistry[:enroll_app].setting(:state_abbreviation).item,
      zip: '01001',
      county: 'Hampden'
    )
  end

  describe '#call' do
    subject { described_class.new.call(input_object) }

    context 'when:
      - application is in draft state
      - address is of kind mailing
      - input object is a valid FinancialAssistance::Locations::Address
      ' do
      let(:application_aasm_state) { 'draft' }
      let(:input_object) { address }
      let(:address_kind) { 'mailing' }

      it 'destroys the address and returns a success' do
        expect(subject).to be_a(Dry::Monads::Result::Success)
        expect(subject.success).to eq(
          "Successfully destroyed mailing address of the applicant with full_name: #{applicant.full_name} and person_hbx_id: #{applicant.person_hbx_id}."
        )
      end
    end

    context 'when:
      - application is NOT in draft state
      - address is of kind mailing
      - input object is a valid FinancialAssistance::Locations::Address
      ' do
      let(:application_aasm_state) { 'determined' }
      let(:input_object) { address }
      let(:address_kind) { 'mailing' }

      it 'does not destroy the address and returns a failure' do
        expect(subject).to be_a(Dry::Monads::Result::Failure)
        expect(subject.failure).to eq(
          "The application with hbx_id: #{application.hbx_id} for given applicant with person_hbx_id: #{applicant.person_hbx_id} is not a draft application, address cannot be destroyed/deleted."
        )
      end
    end

    context 'when:
      - application is in draft state
      - address is NOT of kind mailing
      - input object is a valid FinancialAssistance::Locations::Address
      ' do
      let(:application_aasm_state) { 'draft' }
      let(:input_object) { address }
      let(:address_kind) { 'home' }

      it 'does not destroy the address and returns a failure' do
        expect(subject).to be_a(Dry::Monads::Result::Failure)
        expect(subject.failure).to eq(
          'Given address not of kind mailing, cannot be destroyed/deleted.'
        )
      end
    end

    context 'when:
      - application is in draft state
      - address is of kind mailing
      - input object is NOT a valid FinancialAssistance::Locations::Address
      ' do
      let(:application_aasm_state) { 'draft' }
      let(:input_object) { 'address' }
      let(:address_kind) { 'mailing' }

      it 'does not destroy the address and returns a failure' do
        expect(subject).to be_a(Dry::Monads::Result::Failure)
        expect(subject.failure).to eq(
          "Given input: #{input_object} is not a valid FinancialAssistance::Locations::Address."
        )
      end
    end

    context 'when:
      - application is in draft state
      - address is of kind mailing
      - input object is a valid FinancialAssistance::Locations::Address
      - mailing address is NOT to be destroyed
      ' do
      let(:application_aasm_state) { 'draft' }
      let(:input_object) { address }
      let(:address_kind) { 'mailing' }

      before do
        allow(address).to receive(:destroy!).and_raise(
          RuntimeError.new('Mocking error to test failure scenario.')
        )
      end

      it 'does not destroy the address and returns a failure' do
        expect(subject).to be_a(Dry::Monads::Result::Failure)
        expect(subject.failure).to eq(
          "Unable to destroy mailing address of the applicant with full_name: #{applicant.full_name} and person_hbx_id: #{applicant.person_hbx_id}."
        )
      end
    end
  end
end
