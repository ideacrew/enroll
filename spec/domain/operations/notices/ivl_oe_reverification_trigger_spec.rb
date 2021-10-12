# frozen_string_literal: true

require 'rails_helper'
require "#{FinancialAssistance::Engine.root}/spec/shared_examples/medicaid_gateway/test_case_d_response"

RSpec.describe ::Operations::Notices::IvlOeReverificationTrigger, dbclean: :after_each do

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  describe 'ivl open enrollment reverification trigger' do
    include_context 'cms ME simple_scenarios test_case_d'

    let(:person) { create(:person, :with_consumer_role)}
    let(:family) { create(:family, :with_primary_family_member, person: person)}
    let(:aasm_state) { 'determined' }

    let!(:application) do
      create(
        :financial_assistance_application,
        family_id: family.id,
        aasm_state: aasm_state,
        eligibility_response_payload: response_payload.to_json,
        assistance_year: 2022 # should get rid of hard coded year
      )
    end

    let(:is_ia_eligible) { true }
    let(:is_medicaid_chip_eligible) { false }
    let(:is_without_assistance) { false }

    let!(:faa_applicant) do
      create(
        :financial_assistance_applicant,
        :male,
        :with_home_address,
        application: application,
        first_name: person.first_name,
        last_name: person.last_name,
        family_member_id: family.primary_family_member.id,
        is_ia_eligible: is_ia_eligible,
        is_medicaid_chip_eligible: is_medicaid_chip_eligible,
        is_without_assistance: is_without_assistance,
        dob: person.dob,
        ssn: person.ssn,
        is_primary_applicant: true,
        citizen_status: 'us_citizen'
      )
    end

    let(:issuer) { create(:benefit_sponsors_organizations_issuer_profile, abbrev: 'ANTHM') }
    let(:product) { create(:benefit_markets_products_health_products_health_product, :ivl_product, issuer_profile: issuer) }

    let(:enrollment) do
      create(
        :hbx_enrollment,
        :with_enrollment_members,
        :individual_unassisted,
        family: family,
        product_id: product.id,
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

    context 'with valid params' do
      let(:params) {{ family: family }}

      it 'should return success' do
        result = subject.call(params)
        expect(result.success?).to be_truthy
      end
    end
  end
end
