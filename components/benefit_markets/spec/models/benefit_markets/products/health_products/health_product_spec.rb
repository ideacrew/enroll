require 'rails_helper'

module BenefitMarkets
  RSpec.describe Products::HealthProducts::HealthProduct, type: :model do

    let(:this_year)               { TimeKeeper.date_of_record.year }
    # let(:this_year)               { BenefitMarkets.time_keeper_class.constantize.date_of_record.year }
    let(:benefit_market_kind)     { :aca_shop }
    let(:application_period)      { Date.new(this_year, 1, 1)..Date.new(this_year, 12, 31) }

    let(:hbx_id)                  { "6262626262" }
    let(:issuer_profile_urn)      { "urn:openhbx:terms:v1:organization:name#safeco" }
    let(:title)                   { "SafeCo Active Life $0 Deductable Premier" }
    let(:description)             { "Highest rated and highest value" }

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
    let(:service_area)            { BenefitMarkets::Locations::ServiceArea.new }
    let(:rating_areas)            { [BenefitMarkets::Locations::RatingArea.new, Locations::RatingArea.new] }



    let(:params) do 
      {
        benefit_market_kind: benefit_market_kind,
        application_period: application_period,
        hbx_id: hbx_id,
        issuer_profile_urn: issuer_profile_urn,
        title: title,
        description: description,

        hios_id: hios_id,
        hios_base_id: hios_base_id,
        csr_variant_id: csr_variant_id,
        health_plan_kind: health_plan_kind,
        metal_level_kind: metal_level_kind,
        ehb: ehb,
        is_standard_plan: is_standard_plan,
        provider_directory_url: provider_directory_url,
        rx_formulary_url: rx_formulary_url,

        # renewal_product: renewal_product,
        # catastrophic_age_off_product: catastrophic_age_off_product,
        # sbc_document: sbc_document,
        # service_area: service_area,
        # rating_areas: rating_areas,
      }
    end



    context "A new HealthProduct instance" do

      context "that's missing required params" do

        context "with no arguments" do
          subject { described_class.new }

          it "should not be valid" do
            subject.validate
            expect(subject).to_not be_valid
          end
        end

        context "without hios_id" do
          subject { described_class.new(params.except(:hios_id)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:hios_id]).to include("can't be blank")
          end
        end


      end

      context "with invalid params" do
        let(:invalid_year)                { TimeKeeper.date_of_record.year + 4  }
        let(:invalid_application_period)  { Date.new(invalid_year, 1, 1)..Date.new(invalid_year, 12, 31) }
        let(:invalid_metal_level_kind)    { :copper }


        it "should be invalid"
      end

      context "with all valid params" do
        it "should be valid"
      end

    end




  end
end
