# frozen_string_literal: true

require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"

require "rails_helper"

module Operations
  # payment transaction namespace
  module PaymentTransactions
    RSpec.describe Create,  dbclean: :after_each do
      include_context "setup benefit market with market catalogs and product packages"

      subject do
        described_class.new.call(params)
      end

      let!(:person)          { FactoryBot.create(:person, :with_consumer_role) }
      let!(:family)          { FactoryBot.create(:family, :with_primary_family_member, person: person) }
      let!(:issuer_profile)  { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile)}
      let!(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, issuer_profile: issuer_profile) }

      let!(:hbx_enrollment)  do
        FactoryBot.create(:hbx_enrollment, :individual_unassisted,
                          household: family.active_household,
                          family: family,
                          product: product)
      end

      describe 'given invalid params' do
        context 'given params as nil' do
          let(:params) {{hbx_enrollment: nil}}
          let(:error_message) {'Is not a hbx enrollment object'}

          it 'fails' do
            expect(subject).not_to be_success
            expect(subject.failure).to eq error_message
          end
        end

        context 'given enrollment without effective on' do
          let(:params) {{hbx_enrollment: hbx_enrollment}}
          let(:error_message) {{:enrollment_effective_date => ["must be a date"]}}

          before :each do
            hbx_enrollment.unset(:effective_on)
          end

          it 'fails' do
            expect(subject).not_to be_success
            expect(subject.failure).to eq error_message
          end
        end

        context 'given enrollment without product' do
          let(:params) {{hbx_enrollment: hbx_enrollment}}
          let(:error_message) {{:carrier_id => ["must be a string"]}}

          before :each do
            hbx_enrollment.product = nil
            hbx_enrollment.save
          end

          it 'fails' do
            expect(subject).not_to be_success
            expect(subject.failure).to eq error_message
          end
        end
      end

      describe 'Given valid params' do
        let(:params) {{hbx_enrollment: hbx_enrollment}}

        context 'Operation should result in success' do
          it 'should create a payment transaction instance for family' do
            expect(subject).to be_success
          end
        end

        context 'Should create payment transaction for family' do
          it 'should create payment transaction for family' do
            expect(family.payment_transactions.count).to eq 0
            expect(subject).to be_success
            expect(family.payment_transactions.count).to eq 1
          end

          # Additional spec coverage for removing build method on payment transaction.
          it 'should create payment transaction for family related to enrollment ' do
            expect(subject).to be_success
            expect(family.payment_transactions.first.enrollment_id).to eq hbx_enrollment.id
            expect(family.payment_transactions.first.carrier_id).to eq issuer_profile.id
            expect(family.payment_transactions.first.enrollment_effective_date).to eq hbx_enrollment.effective_on
          end
        end
      end
    end
  end
end
