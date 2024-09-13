# frozen_string_literal: true

RSpec.describe Operations::Migrations::Applications::BenchmarkPremiums::FetchBenchmarkProducts, type: :model do
  require File.join(Rails.root, 'spec/shared_contexts/benchmark_products')

  describe '#call' do
    include_context 'family with 2 family members with county_zip, rating_area & service_area'
    include_context '3 dental products with different rating_methods, different child_only_offerings and 3 health products'
    include_context '3 dental products with different rating_methods, different child_only_offerings and 3 health products'

    let(:application) do
      FactoryBot.create(
        :financial_assistance_application,
        family: family,
        effective_date: TimeKeeper.date_of_record.beginning_of_year
      )
    end

    let(:applicant1) do
      appl1 = FactoryBot.create(
        :financial_assistance_applicant,
        :with_home_address,
        dob: person1.dob,
        family_member_id: family_member1.id,
        person_hbx_id: person1.hbx_id,
        is_primary_applicant: true,
        application: application
      )

      appl1.rating_address.update_attributes!(county: 'York', zip: '04001', state: 'ME')
      appl1
    end

    let(:valid_county_zip_params) { { county: 'York', zip: '04001', state: 'ME' } }

    let(:invalid_county_zip_params) { { county: 'Dummy', zip: '11111', state: 'NY' } }

    let(:applicant2) do
      appl2 = FactoryBot.create(
        :financial_assistance_applicant,
        :with_home_address,
        dob: person2.dob,
        family_member_id: family_member2.id,
        person_hbx_id: person2.hbx_id,
        is_primary_applicant: false,
        application: application
      )

      appl2.rating_address.update_attributes!(valid_county_zip_params)
      appl2
    end

    before do
      ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
    end

    context 'with valid params' do
      before do
        applicant1
        applicant2
      end

      let(:input_params) do
        { application: application, effective_date: application.effective_date }
      end

      let(:benchmark_premiums) do
        {
          health_only_slcsp_premiums: [
            { member_identifier: person1.hbx_id, monthly_premium: 590.0 },
            { member_identifier: person2.hbx_id, monthly_premium: 590.0 }
          ],
          health_only_lcsp_premiums: [
            { member_identifier: person1.hbx_id, monthly_premium: 200.0 },
            { member_identifier: person2.hbx_id, monthly_premium: 200.0 }
          ]
        }
      end

      it 'returns lcsp and slcsp benchmark premiums' do
        result = subject.call(input_params)
        expect(result).to be_success
        expect(result.success).to eq(benchmark_premiums)
      end
    end

    context "when:
      - primary applicant's home address is not within state
      - primary applicant's mailing address is within state
      " do

      before do
        applicant1.home_address.update_attributes!(**invalid_county_zip_params)
        applicant1.addresses.create(
          {
            kind: 'mailing',
            address_1: '1234 Main St',
            address_2: 'Apt 1',
            city: 'Portland',
          }.merge(valid_county_zip_params)
        )
        applicant2
      end

      let(:input_params) do
        { application: application, effective_date: application.effective_date }
      end

      let(:benchmark_premiums) do
        {
          health_only_slcsp_premiums: [
            { member_identifier: person1.hbx_id, monthly_premium: 590.0 },
            { member_identifier: person2.hbx_id, monthly_premium: 590.0 }
          ],
          health_only_lcsp_premiums: [
            { member_identifier: person1.hbx_id, monthly_premium: 200.0 },
            { member_identifier: person2.hbx_id, monthly_premium: 200.0 }
          ]
        }
      end

      it 'returns lcsp and slcsp benchmark premiums' do
        result = subject.call(input_params)
        expect(result).to be_success
        expect(result.success).to eq(benchmark_premiums)
      end
    end

    context "when:
      - primary applicant's home address is not within state
      - primary applicant's mailing address is not within state
      - primary person's home address is within state
      " do

      before do
        applicant1.home_address.update_attributes!(**invalid_county_zip_params)
        applicant1.addresses.create(
          {
            kind: 'mailing',
            address_1: '1234 Main St',
            address_2: 'Apt 1',
            city: 'Portland',
          }.merge(invalid_county_zip_params)
        )
        applicant2
      end

      let(:input_params) do
        { application: application, effective_date: application.effective_date }
      end

      let(:benchmark_premiums) do
        {
          health_only_slcsp_premiums: [
            { member_identifier: person1.hbx_id, monthly_premium: 590.0 },
            { member_identifier: person2.hbx_id, monthly_premium: 590.0 }
          ],
          health_only_lcsp_premiums: [
            { member_identifier: person1.hbx_id, monthly_premium: 200.0 },
            { member_identifier: person2.hbx_id, monthly_premium: 200.0 }
          ]
        }
      end

      it 'returns lcsp and slcsp benchmark premiums' do
        result = subject.call(input_params)
        expect(result).to be_success
        expect(result.success).to eq(benchmark_premiums)
      end
    end

    context "when:
      - primary applicant's home address is not within state
      - primary applicant's mailing address is not within state
      - primary person's home address is not within state
      - primary person's mailing address is within state
      " do

      before do
        applicant1.home_address.update_attributes!(**invalid_county_zip_params)
        applicant1.addresses.create(
          {
            kind: 'mailing',
            address_1: '1234 Main St',
            address_2: 'Apt 1',
            city: 'Portland',
          }.merge(invalid_county_zip_params)
        )
        applicant2
        per_home_add = person1.home_address
        per_mailing_add = person1.mailing_address
        per_home_add.assign_attributes(invalid_county_zip_params)
        per_mailing_add.assign_attributes(valid_county_zip_params)
        person1.save!
      end

      let(:input_params) do
        { application: application, effective_date: application.effective_date }
      end

      let(:benchmark_premiums) do
        {
          health_only_slcsp_premiums: [
            { member_identifier: person1.hbx_id, monthly_premium: 590.0 },
            { member_identifier: person2.hbx_id, monthly_premium: 590.0 }
          ],
          health_only_lcsp_premiums: [
            { member_identifier: person1.hbx_id, monthly_premium: 200.0 },
            { member_identifier: person2.hbx_id, monthly_premium: 200.0 }
          ]
        }
      end

      it 'returns lcsp and slcsp benchmark premiums' do
        result = subject.call(input_params)
        expect(result).to be_success
        expect(result.success).to eq(benchmark_premiums)
      end
    end

    context 'with invalid params' do
      let(:input_params) do
        { application: 'application', effective_date: 'application.effective_date' }
      end

      it 'returns a failure' do
        expect(
          subject.call(input_params).failure
        ).to eq("Invalid params - #{input_params}. Expected application and effective_date.")
      end
    end
  end
end
