require 'rails_helper'

module BenefitMarkets
  RSpec.describe Products::HealthProducts::HealthProduct, type: :model do

    let(:this_year)               { TimeKeeper.date_of_record.year }
    let(:benefit_market_kind)     { :aca_shop }
    let(:application_period)      { Date.new(this_year, 1, 1)..Date.new(this_year, 12, 31) }

    let(:hbx_id)                  { "6262626262" }
    let(:issuer_profile_urn)      { "urn:openhbx:terms:v1:organization:name#safeco" }
    let(:title)                   { "SafeCo Active Life $0 Deductable Premier" }
    let(:description)             { "Highest rated and highest value" }
    let(:service_area)            { BenefitMarkets::Locations::ServiceArea.new }

    let(:hios_id)                 { "86052DC0400001-01" }
    let(:hios_base_id)            { "86052DC0400001" }
    let(:csr_variant_id)          { "01" }

    let(:health_plan_kind)        { :pos }
    let(:metal_level_kind)        { :silver }
    let(:ehb)                     { 0.9 }
    let(:is_standard_plan)        { false }
    let(:provider_directory_url)  { "http://example.com/providers" }
    let(:rx_formulary_url)        { "http://example.com/formularies/1" }

    let(:sbc_document)            { Object.new }

    let(:rating_area)         { BenefitMarkets::Locations::RatingArea.new }
    let(:quarter_1)           { Date.new(this_year, 1, 1)..Date.new(this_year, 3, 31) }
    let(:premium_q1_age_20)   { BenefitMarkets::Products::PremiumTuple.new(age: 20, cost: 201) }
    let(:premium_q1_age_30)   { BenefitMarkets::Products::PremiumTuple.new(age: 30, cost: 301) }
    let(:premium_q1_age_40)   { BenefitMarkets::Products::PremiumTuple.new(age: 40, cost: 401) }
    let(:premium_table_q1)    { BenefitMarkets::Products::PremiumTable.new(
                                  effective_period: quarter_1,
                                  rating_area: rating_area,
                                  premium_tuples: [premium_q1_age_20, premium_q1_age_30, premium_q1_age_40],
                                ) }
    let(:premium_tables)      { [premium_table_q1] }


    let(:params) do 
      {
        benefit_market_kind:      benefit_market_kind,
        application_period:       application_period,
        hbx_id:                   hbx_id,
        # issuer_profile_urn:       issuer_profile_urn,
        title:                    title,
        description:              description,
        service_area:             service_area,
        premium_tables:           premium_tables,

        hios_id:                  hios_id,
        hios_base_id:             hios_base_id,
        csr_variant_id:           csr_variant_id,
        health_plan_kind:         health_plan_kind,
        metal_level_kind:         metal_level_kind,
        ehb:                      ehb,
        is_standard_plan:         is_standard_plan,
        provider_directory_url:   provider_directory_url,
        rx_formulary_url: rx_formulary_url,

        # renewal_product: renewal_product,
        # catastrophic_age_off_product: catastrophic_age_off_product,
        # sbc_document: sbc_document,
      }
    end

    context "A new HealthProduct instance" do
      context "with no arguments" do
        subject { described_class.new }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "without required params" do

        context "that's missing hios_id" do
          subject { described_class.new(params.except(:hios_id)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:hios_id]).to include("can't be blank")
          end
        end

        context "that's missing health_plan_kind" do
          subject { described_class.new(params.except(:health_plan_kind)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:health_plan_kind]).to include("can't be blank")
          end
        end
      end

      context "with invalid params" do
        context "and benefit_market_kind is invalid" do
          let(:invalid_metal_level_kind)  { :copper }

          subject { described_class.new(params.except(:metal_level_kind).merge({metal_level_kind: invalid_metal_level_kind})) }

          it "should not be valid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:metal_level_kind]).to include("#{invalid_metal_level_kind} is not a valid metal level kind")
          end
        end

        context "and ehb is invalid" do
          let(:invalid_ehb)  { 0.0 }

          subject { described_class.new(params.except(:ehb).merge({ehb: invalid_ehb})) }

          it "should not be valid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:ehb]).to include("must be greater than 0.0")
          end
        end
      end

      context "with all valid params" do
        subject { described_class.new(params) }

        it "should be valid" do
          subject.validate
          expect(subject).to be_valid
        end
      end
    end

    describe '#covers_pediatric_dental?' do
      let!(:health_product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :silver, kind: :health) }
      let!(:qhp) do
        ::Products::Qhp.create(
          {
            issuer_id: "1234", state_postal_code: "DC",
            active_year: health_product.application_period.min.year,
            standard_component_id: health_product.hios_base_id,
            plan_marketing_name: "gold plan", hios_product_id: "1234",
            network_id: "123", service_area_id: "12", formulary_id: "123",
            is_new_plan: "yes", plan_type: "test", metal_level: "bronze",
            unique_plan_design: "", qhp_or_non_qhp: "qhp",
            insurance_plan_pregnancy_notice_req_ind: "yes",
            is_specialist_referral_required: "yes", hsa_eligibility: "yes",
            emp_contribution_amount_for_hsa_or_hra: "1000", child_only_offering: "no",
            is_wellness_program_offered: "yes", plan_effective_date: "04/01/2015".to_date,
            out_of_country_coverage: "yes", out_of_service_area_coverage: "yes",
            national_network: "yes", summary_benefit_and_coverage_url: "www.example.com"
          }
        )
      end
      let!(:child_dental_checkup) { qhp.qhp_benefits.create(benefit_type_code: 'Dental Check-Up for Children', is_benefit_covered: 'Covered') }

      context "with 'Dental Check-Up for Children' qhp_benefit" do
        it 'returns false' do
          expect(health_product.covers_pediatric_dental?).to eq(false)
        end
      end

      context "with 'Dental Check-Up for Children' & 'Basic Dental Care - Child' qhp_benefits" do
        let!(:child_basic_dental) { qhp.qhp_benefits.create(benefit_type_code: 'Basic Dental Care - Child', is_benefit_covered: 'Covered') }

        it 'returns false' do
          expect(health_product.covers_pediatric_dental?).to eq(false)
        end
      end

      context "with 'Dental Check-Up for Children', 'Basic Dental Care - Child' & 'Major Dental Care - Child' qhp_benefits" do
        let!(:child_basic_dental) { qhp.qhp_benefits.create(benefit_type_code: 'Basic Dental Care - Child', is_benefit_covered: 'Covered') }
        let!(:child_major_dental) { qhp.qhp_benefits.create(benefit_type_code: 'Major Dental Care - Child', is_benefit_covered: 'Covered') }

        it 'returns true' do
          expect(health_product.covers_pediatric_dental?).to eq(true)
        end
      end
    end
  end
end
