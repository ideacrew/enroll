# frozen_string_literal: true

require 'rails_helper'
require "#{FinancialAssistance::Engine.root}/spec/shared_examples/medicaid_gateway/test_case_d_response"

RSpec.describe ::Operations::Notices::IvlOeReverificationTrigger, dbclean: :after_each do
  include Dry::Monads[:do, :result]

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  describe 'ivl open enrollment reverification trigger' do
    include_context 'cms ME simple_scenarios test_case_d'

    let!(:person) { create(:person, hbx_id: "732020")}
    let(:contact_method) { 'Paper and Electronic communications' }
    let!(:consumer_role) { create(:consumer_role, person: person, contact_method: contact_method) }
    let!(:family) { create(:family, :with_primary_family_member, person: person)}
    let!(:household) { create(:household, family: family) }
    let!(:tax_household) { create(:tax_household, household: household, submitted_at: TimeKeeper.date_of_record) }
    let!(:application) do
      create(
        :financial_assistance_application,
        family_id: family.id,
        aasm_state: 'submitted',
        hbx_id: "830293",
        assistance_year: 2022,
        eligibility_response_payload: response_payload.to_json,
        effective_date: DateTime.new(2021,1,1,4,5,6)
      )
    end
    let!(:applicant) do
      create(
        :applicant,
        first_name: person.first_name,
        last_name: person.last_name,
        dob: person.dob,
        gender: person.gender,
        ssn: person.ssn,
        application: application,
        ethnicity: [],
        is_ia_eligible: true,
        is_primary_applicant: true,
        person_hbx_id: person.hbx_id,
        is_self_attested_blind: false,
        is_applying_coverage: true,
        is_required_to_file_taxes: true,
        is_filing_as_head_of_household: true,
        is_pregnant: false,
        has_job_income: false,
        has_self_employment_income: false,
        has_unemployment_income: false,
        has_other_income: false,
        has_deductions: false,
        is_self_attested_disabled: true,
        is_physically_disabled: false,
        citizen_status: 'us_citizen',
        has_enrolled_health_coverage: false,
        has_eligible_health_coverage: false,
        has_eligible_medicaid_cubcare: false,
        is_claimed_as_tax_dependent: false,
        is_incarcerated: false,
        net_annual_income: 10_078.90,
        is_post_partum_period: false
      )
    end

    let!(:eligibility_determination) { create(:financial_assistance_eligibility_determination, application: application) }

    let(:premiums_hash) do
      {
        [person.hbx_id] => {:health_only => {person.hbx_id => [{:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}]}}
      }
    end

    let(:slcsp_info) do
      {
        person.hbx_id => {:health_only_slcsp_premiums => {:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}}
      }
    end

    let(:lcsp_info) do
      {
        person.hbx_id => {:health_only_lcsp_premiums => {:cost => 100.0, :member_identifier => person.hbx_id, :monthly_premium => 100.0}}
      }
    end

    let(:fetch_double) { double(:new => double(call: double(:value! => premiums_hash)))}
    let(:fetch_slcsp_double) { double(:new => double(call: double(:value! => slcsp_info)))}
    let(:fetch_lcsp_double) { double(:new => double(call: double(:value! => lcsp_info)))}

    let(:obj)  { FinancialAssistance::Operations::Transfers::MedicaidGateway::TransferAccount.new }
    let(:event) { Success(double) }

    let(:hbx_profile) { create(:hbx_profile) }
    let(:benefit_sponsorship) { create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
    let!(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }

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

    before do
      allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
      allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
      allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)
      stub_const('::Operations::Products::Fetch', fetch_double)
      stub_const('::Operations::Products::FetchSlcsp', fetch_slcsp_double)
      stub_const('::Operations::Products::FetchLcsp', fetch_lcsp_double)
      allow(FinancialAssistance::Operations::Transfers::MedicaidGateway::TransferAccount).to receive(:new).and_return(obj)
      allow(obj).to receive(:build_event).and_return(event)
      allow(event.success).to receive(:publish).and_return(true)
      stub_const('::Operations::Products::Fetch', fetch_double)
      stub_const('::Operations::Products::FetchSlcsp', fetch_slcsp_double)
      stub_const('::Operations::Products::FetchLcsp', fetch_lcsp_double)
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

    context 'build_consumer_role' do
      let(:payload) { ::Operations::Notices::IvlOeReverificationTrigger.new.send('build_consumer_role', consumer_role) }

      it 'should include contact_method in the hash' do
        expect(payload[:contact_method]).to eq(contact_method)
      end
    end

    context 'build family member hash' do
      let!(:inactive_person){ create(:person, hbx_id: "732021")}
      let!(:family_member) { create(:family_member, family: family, person: inactive_person, is_active: false)}
      let(:payload) { ::Operations::Notices::IvlOeReverificationTrigger.new.send('build_family_member_hash', family) }

      it 'should include only active family members in the hash' do
        expect(payload.any? {|members| members[:person][:hbx_id].eql?(person.hbx_id)}).to be_truthy
        expect(payload.any? {|members| members[:person][:hbx_id].eql?(inactive_person.hbx_id)}).to be_falsey
      end
    end
  end
end
