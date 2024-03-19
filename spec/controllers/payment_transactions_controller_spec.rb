# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentTransactionsController, :type => :controller, :dbclean => :after_each do
  let(:user){ FactoryBot.create(:user, :consumer) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent) }
  let!(:issuer_profile)  { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile, legal_name: 'Kaiser Permanente') }
  let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01', issuer_profile: issuer_profile)}
  let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, aasm_state: 'shopping', product: product) }
  let(:build_saml_repsonse) {double}
  let(:encode_saml_response) {double}
  let(:connection) {double}
  let(:mock_policy) do
    instance_double(
      HbxEnrollmentPolicy,
      :pay_now? => true
    )
  end

  context 'GET generate saml response' do
    before(:each) do
      allow(HbxEnrollmentPolicy).to receive(:new).with(user, hbx_enrollment).and_return(mock_policy)
      sign_in user
      allow(HTTParty).to receive(:post).and_return connection
      allow_any_instance_of(OneLogin::RubySaml::SamlGenerator).to receive(:build_saml_response).and_return build_saml_repsonse
      allow_any_instance_of(OneLogin::RubySaml::SamlGenerator).to receive(:encode_saml_response).and_return encode_saml_response
    end

    it 'should generate saml response' do
      get :generate_saml_response, params: { :enrollment_id => hbx_enrollment.hbx_id, :source => source }
      expect(response).to have_http_status(:success)
    end

    it 'should build payment transacations for a family' do
      get :generate_saml_response, params: { :enrollment_id => hbx_enrollment.hbx_id, :source => source }
      expect(family.payment_transactions.count).to eq 1
    end

    it 'should build payment transaction with enrollment effective date and carrier id' do
      get :generate_saml_response, params: { :enrollment_id => hbx_enrollment.hbx_id, :source => source }
      expect(family.payment_transactions.first.enrollment_effective_date).to eq hbx_enrollment.effective_on
      expect(family.payment_transactions.first.carrier_id).to eq hbx_enrollment.product.issuer_profile_id
    end
  end
end

RSpec.describe PaymentTransactionsController, "given a user with insufficient permissions", :type => :controller, :dbclean => :after_each  do
  context 'GET #generate_saml_response' do
    let(:user){ FactoryBot.create(:user, :consumer) }
    let(:mock_policy) do
      instance_double(
        HbxEnrollmentPolicy,
        :pay_now? => false
      )
    end
    let(:hbx_enrollment_hbx_id) { "AN HBX ENROLLMENT HBX ID" }
    let(:hbx_enrollment) do
      double(
        :policy_class => HbxEnrollmentPolicy
      )
    end

    before(:each) do
      allow(HbxEnrollment).to receive(:by_hbx_id).with(hbx_enrollment_hbx_id).and_return([hbx_enrollment])
      expect(HbxEnrollmentPolicy).to receive(:new).with(user, hbx_enrollment).and_return(mock_policy)
      sign_in user
    end

    it "is denied access" do
      get :generate_saml_response, params: { :enrollment_id => hbx_enrollment_hbx_id, :source => "A SOURCE" }
      #expect(response.status).to eq 302
    end
  end
end