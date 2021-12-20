# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Notices::IvlFinalRenewalEligibilityNotice, dbclean: :after_each do

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  describe 'ivl fre notice' do
    let(:person) { create(:person, :with_consumer_role)}
    let(:family) { create(:family, :with_primary_family_member, person: person)}
    let(:issuer) { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile, abbrev: 'ANTHM') }
    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :ivl_product, issuer_profile: issuer) }
    let(:aasm_state) { 'auto_renewing' }
    let(:effective_on) { TimeKeeper.date_of_record.next_year.beginning_of_year }
    let!(:enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        :with_enrollment_members,
        :individual_unassisted,
        family: family,
        aasm_state: aasm_state,
        product_id: product.id,
        effective_on: effective_on,
        applied_aptc_amount: Money.new(44_500),
        consumer_role_id: person.consumer_role.id,
        enrollment_members: family.family_members
      )
    end

    context 'with invalid params' do
      let(:params) {{}}

      it 'should return failure' do
        result = subject.call(params)
        expect(result.failure?).to be_truthy
        expect(result.failure).to eq 'Missing Family'
      end
    end

    context 'payload' do
      before do
        issuer.office_locations.first.phone.update_attributes!(full_phone_number: '1234567890', extension: nil)
      end

      let(:payload) { ::Operations::Notices::IvlFinalRenewalEligibilityNotice.new.send('build_payload', family).success }

      it 'should contain phone number in the desired format' do
        expect(payload[:households][0][:hbx_enrollments][0][:issuer_profile_reference][:phone]).to eq "(123) 456-7890"
      end
    end

    context 'with valid params' do
      before :each do
        allow_any_instance_of(Events::Individual::Notices::FinalRenewalEligibilityDetermined).to receive(:publish).and_return true
      end

      let(:params) {{ family: family }}

      it 'should return success' do
        result = subject.call(params)
        expect(result.success?).to be_truthy
      end

      context 'when family doesnot have auto renewing enrollments' do

        let(:aasm_state) { 'coverage_selected' }

        it 'should return failure' do
          result = subject.call(params)
          expect(result.failure).to eq "Family does not have #{effective_on} auto_renewing enrollments"
        end

      end
    end
  end
end
