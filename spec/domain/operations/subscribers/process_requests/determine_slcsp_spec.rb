# frozen_string_literal: true

require "#{FinancialAssistance::Engine.root}/spec/shared_examples/medicaid_gateway/test_case_d_response"
require File.join(Rails.root, 'spec/shared_contexts/benchmark_products')

RSpec.describe Operations::Subscribers::ProcessRequests::DetermineSlcsp, type: :model, dbclean: :after_each do
  include Dry::Monads[:do, :result]

  describe '#call' do
    subject { described_class.new.call(mm_application) }

    context 'invalid mm_application input' do
      let(:mm_application) { { test: 'test' } }

      it 'should return a failure' do
        expect(subject.failure?).to be_truthy
      end
    end

    context 'valid input' do
      include_context 'cms ME simple_scenarios test_case_d'

      let(:member_dob) { Date.new(current_date.year - 12, current_date.month, current_date.day) }
      let(:person) { FactoryBot.create(:person, :with_consumer_role, first_name: 'Gerald', last_name: 'Rivers', dob: member_dob) }
      let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
      let!(:application) { FactoryBot.create(:financial_assistance_application, hbx_id: '200000126', aasm_state: "submitted", family_id: family.id, effective_date: TimeKeeper.date_of_record) }
      let!(:ed) do
        eli_d = FactoryBot.create(:financial_assistance_eligibility_determination, application: application)
        eli_d.update_attributes!(hbx_assigned_id: '12345')
        eli_d
      end
      let!(:applicant) do
        FactoryBot.create(:financial_assistance_applicant,
                          eligibility_determination_id: ed.id,
                          person_hbx_id: '95',
                          is_primary_applicant: true,
                          first_name: 'Gerald',
                          last_name: 'Rivers',
                          dob: member_dob,
                          application: application)
      end
      let(:mm_application) { ::AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(response_payload).success.to_h }
      let(:health_product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :silver, :with_issuer_profile, csr_variant_id: '01', ehb: 1.0) }
      let(:benchmark_product_hash) do
        {
          family_id: family.id,
          effective_date: application.effective_date,
          primary_rating_address_id: BSON::ObjectId.new,
          rating_area_id: BSON::ObjectId.new,
          exchange_provided_code: 'R-ME001',
          service_area_ids: [BSON::ObjectId.new],
          household_group_benchmark_ehb_premium: 200.90,
          households: [
            {
              household_id: 'a12bs6dbs1',
              type_of_household: 'adult_only',
              household_benchmark_ehb_premium: 200.90,
              health_product_hios_id: '123',
              health_product_id: health_product.id,
              health_ehb: 1.0,
              household_health_benchmark_ehb_premium: 200.90,
              health_product_covers_pediatric_dental_costs: false,
              members: [
                {
                  family_member_id: family.primary_applicant.id,
                  relationship_with_primary: 'self',
                  date_of_birth: member_dob,
                  age_on_effective_date: 30
                }
              ]
            }
          ]
        }
      end
      let(:benchmark_product) { ::Operations::BenchmarkProducts::Initialize.new.call(benchmark_product_hash).success }

      before do
        health_product.issuer_profile.update_attributes!(abbrev: 'BCBS')
        person.update_attributes!(hbx_id: '95')
        allow(::Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts).to receive(:new).and_return(
          double('IdentifySlcspWithPediatricDentalCosts', call: Success(benchmark_product))
        )
      end

      it 'should return entity' do
        expect(subject.success).to be_a(AcaEntities::MagiMedicaid::Application)
        expect(subject.success.benchmark_product.to_h).not_to be_empty
      end
    end

    context 'with more than 3 children' do
      include_context 'application with more than 3 children'
      include_context '3 dental products with different rating_methods, different child_only_offerings and 3 health products'
      let(:mm_application) { mm_application_entity.to_h }

      before do
        mm_application[:assistance_year] = TimeKeeper.date_of_record.year
        mm_application[:aptc_effective_date] = TimeKeeper.date_of_record.beginning_of_year.to_date
        allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate) { |_id, _start, age| age * 1.0 }
        allow(EnrollRegistry[:enroll_app].settings(:rating_areas)).to receive(:item).and_return('county')
        allow(EnrollRegistry[:service_area].settings(:service_area_model)).to receive(:item).and_return('county')
      end

      it 'should return entity' do
        expect(subject.success).to be_a(AcaEntities::MagiMedicaid::Application)
        expect(subject.success.benchmark_product.to_h).not_to be_empty
      end
    end
  end
end
