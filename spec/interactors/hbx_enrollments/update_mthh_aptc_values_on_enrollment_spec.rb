# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::HbxEnrollments::UpdateMthhAptcValuesOnEnrollment, :dbclean => :after_each do
  before :all do
    TimeKeeper.set_date_of_record_unprotected!(Date.new(Date.today.year, 6, 1))
  end

  let!(:site_key) { EnrollRegistry[:enroll_app].setting(:site_key).item.upcase }
  let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
  let!(:family)        { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person) }
  let!(:person)       { FactoryBot.create(:person, :with_consumer_role) }
  let!(:address) { family.primary_person.rating_address }
  let!(:effective_date) { TimeKeeper.date_of_record.beginning_of_year }
  let!(:application_period) { effective_date.beginning_of_year..effective_date.end_of_year }
  let!(:rating_area) do
    ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: effective_date) || FactoryBot.create_default(:benefit_markets_locations_rating_area, active_year: effective_date.year)
  end
  let!(:service_area) do
    ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: effective_date).first || FactoryBot.create_default(:benefit_markets_locations_service_area, active_year: effective_date.year)
  end

  let!(:product) do
    prod =
      FactoryBot.create(
        :benefit_markets_products_health_products_health_product,
        :with_issuer_profile,
        :silver,
        benefit_market_kind: :aca_individual,
        kind: :health,
        application_period: application_period,
        service_area: service_area,
        csr_variant_id: '01'
      )
    prod.premium_tables = [premium_table]
    prod.save
    prod
  end

  let!(:premium_table)        { build(:benefit_markets_products_premium_table, effective_period: application_period, rating_area: rating_area) }
  let!(:tax_household_group) do
    family.tax_household_groups.create!(
      assistance_year: TimeKeeper.date_of_record.year,
      source: 'Admin',
      start_on: TimeKeeper.date_of_record.beginning_of_year,
      tax_households: [
        FactoryBot.build(:tax_household, household: family.active_household)
      ]
    )
  end

  let!(:tax_household) do
    tax_household_group.tax_households.first
  end

  let!(:eligibility_determination) do
    determination = family.create_eligibility_determination(effective_date: TimeKeeper.date_of_record.beginning_of_year)
    determination.grants.create(
      key: "AdvancePremiumAdjustmentGrant",
      value: yearly_expected_contribution,
      start_on: TimeKeeper.date_of_record.beginning_of_year,
      end_on: TimeKeeper.date_of_record.end_of_year,
      assistance_year: TimeKeeper.date_of_record.year,
      member_ids: family.family_members.map(&:id).map(&:to_s),
      tax_household_id: tax_household.id
    )

    determination
  end

  let!(:aptc_grant) { eligibility_determination.grants.first }
  let!(:yearly_expected_contribution) { 125.00 * 12 }
  let!(:slcsp_info) do
    OpenStruct.new(
      households: [OpenStruct.new(
        household_id: aptc_grant.tax_household_id,
        household_benchmark_ehb_premium: benchmark_premium,
        members: family.family_members.collect do |fm|
          OpenStruct.new(
            family_member_id: fm.id.to_s,
            relationship_with_primary: fm.primary_relationship,
            date_of_birth: fm.dob,
            age_on_effective_date: fm.age_on(TimeKeeper.date_of_record)
          )
        end
      )]
    )
  end

  let!(:primary_bp) { 500.00 }
  let!(:benchmark_premium) { primary_bp }
  let(:dependents) { family.dependents }
  let(:hbx_en_members) do
    dependents.collect do |dependent|
      FactoryBot.build(:hbx_enrollment_member,
                       applicant_id: dependent.id)
    end
  end

  let!(:enrollment) do
    FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :individual_assisted, family: family, product: product, consumer_role_id: person.consumer_role.id, rating_area_id: rating_area.id, hbx_enrollment_members: hbx_en_members)
  end
  let!(:thhm_enrollment_members) do
    enrollment.hbx_enrollment_members.collect do |member|
      FactoryBot.build(:tax_household_member_enrollment_member, hbx_enrollment_member_id: member.id, family_member_id: member.applicant_id, tax_household_member_id: "123")
    end
  end
  let!(:thhe) do
    FactoryBot.create(:tax_household_enrollment, enrollment_id: enrollment.id, tax_household_id: tax_household.id,
                                                 health_product_hios_id: enrollment.product.hios_id,
                                                 dental_product_hios_id: nil, tax_household_members_enrollment_members: thhm_enrollment_members)
  end

  before do
    allow(::Operations::BenchmarkProducts::IdentifySlcspWithPediatricDentalCosts).to receive(:new).and_return(
      double('IdentifySlcspWithPediatricDentalCosts',
             call: double(:value! => slcsp_info, :success? => true))
    )
    effective_on = hbx_profile.benefit_sponsorship.current_benefit_period.start_on
    enrollment.update_attributes(effective_on: Date.new(effective_on.year, 1, 1), aasm_state: "coverage_selected")
    hbx_profile.benefit_sponsorship.benefit_coverage_periods.each {|bcp| bcp.update_attributes!(slcsp_id: product.id)}
    allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).with(product, effective_on, person.age_on(Date.today), "R-#{site_key}001", 'N').and_return(679.8)
    cr1 = FactoryBot.build(:consumer_role, :contact_method => "Paper Only")
    family.family_members[1].person.consumer_role = cr1
    cr2 = FactoryBot.build(:consumer_role, :contact_method => "Paper Only")
    family.family_members[2].person.consumer_role = cr2
    family.save!
    EnrollRegistry[:temporary_configuration_enable_multi_tax_household_feature].feature.stub(:is_enabled).and_return(true)
    allow(UnassistedPlanCostDecorator).to receive(:new).and_return(double(total_ehb_premium: 1500, total_premium: 1600))
  end


  it "should have 0 applied_aptc_amount" do
    expect(enrollment.applied_aptc_amount.to_f).to be 0.0
  end

  context "aptc family with valid params" do
    let!(:params) do
      {enrollment: enrollment, elected_aptc_pct: 0.85, new_effective_date: enrollment.effective_on}
    end

    it "should set applied_aptc_amount" do
      expect(described_class.call(params).enrollment.applied_aptc_amount.to_f).not_to be 0.0
    end
  end

  context "aptc family with invalid new_effective_date param" do
    let!(:params) do
      {enrollment: enrollment, elected_aptc_pct: 0.85, new_effective_date: nil}
    end

    it "should fail" do
      expect(described_class.call(params).failure?).to be_truthy
      expect(described_class.call(params).message).to eq "new_effective_date is required"
    end
  end

  context "aptc family with invalid elected_aptc_pct param" do
    let!(:params) do
      {enrollment: enrollment, elected_aptc_pct: nil, new_effective_date: enrollment.effective_on}
    end

    it "should fail" do
      expect(described_class.call(params).failure?).to be_truthy
      expect(described_class.call(params).message).to eq "elected_aptc_pct is required"
    end
  end
end
