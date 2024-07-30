# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Individual::OnNewDetermination, type: :model, dbclean: :after_each do
  before :each do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
    DatabaseCleaner.clean
    allow(EnrollRegistry[:apply_aggregate_to_enrollment].feature).to receive(:is_enabled).and_return(false)
  end

  let(:site_key) { EnrollRegistry[:enroll_app].setting(:site_key).item.upcase }
  let!(:person) {FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
  let!(:family) {FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person)}
  let(:sep) {FactoryBot.create(:special_enrollment_period, family: family)}
  let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, title: 'AAA', issuer_profile_id: 'ab1233', metal_level_kind: :silver, benefit_market_kind: :aca_individual)}
  let(:rating_area) { FactoryBot.create(:benefit_markets_locations_rating_area) }
  let!(:enrollment) {FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: product, consumer_role_id: person.consumer_role.id, rating_area_id: rating_area.id)}
  let!(:hbx_enrollment_member1) do
    FactoryBot.create(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record, hbx_enrollment: enrollment, coverage_start_on: TimeKeeper.date_of_record, tobacco_use: 'N')
  end
  let!(:hbx_enrollment_member2) do
    FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[1].id, eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record, hbx_enrollment: enrollment, tobacco_use: 'N')
  end
  let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}

  subject { Operations::Individual::OnNewDetermination }

  describe "when multi tax household enabled" do
    let(:address) { family.primary_person.rating_address }
    let(:effective_date) { TimeKeeper.date_of_record.beginning_of_year }
    let(:application_period) { effective_date.beginning_of_year..effective_date.end_of_year }
    let(:rating_area) do
      ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: effective_date) || FactoryBot.create_default(:benefit_markets_locations_rating_area, active_year: effective_date.year)
    end
    let(:service_area) do
      ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: effective_date).first || FactoryBot.create_default(:benefit_markets_locations_service_area, active_year: effective_date.year)
    end
    let!(:renewal_rating_area) do
      ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: renewal_calender_date) || FactoryBot.create_default(:benefit_markets_locations_rating_area, active_year: renewal_calender_date.year)
    end
    let!(:renewal_service_area) do
      ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: renewal_calender_date).first || FactoryBot.create_default(:benefit_markets_locations_service_area, active_year: renewal_calender_date.year)
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
          csr_variant_id: '01',
          renewal_product_id: renewal_individual_health_product.id
        )
      prod.premium_tables = [premium_table]
      prod.save
      prod
    end
    let(:premium_table)        { build(:benefit_markets_products_premium_table, effective_period: application_period, rating_area: rating_area) }
    let(:renewal_calender_date) { TimeKeeper.date_of_record.beginning_of_year.next_year }
    let(:renewal_application_period) { renewal_calender_date.beginning_of_year..renewal_calender_date.end_of_year }
    let!(:renewal_individual_health_product) do
      prod =
        FactoryBot.create(
          :benefit_markets_products_health_products_health_product,
          :with_issuer_profile,
          :silver,
          benefit_market_kind: :aca_individual,
          kind: :health,
          service_area: renewal_service_area,
          csr_variant_id: '01',
          application_period: renewal_application_period
        )
      prod.premium_tables = [renewal_individual_premium_table]
      prod.save
      prod
    end

    let(:renewal_individual_premium_table) { build(:benefit_markets_products_premium_table, effective_period: renewal_application_period, rating_area: renewal_rating_area) }

    before :each do
      allow(EnrollRegistry[:temporary_configuration_enable_multi_tax_household_feature].feature).to receive(:is_enabled).and_return(true)
      allow(EnrollRegistry[:aca_individual_assistance_benefits].setting(:default_applied_aptc_percentage)).to receive(:item).and_return(1.0)

      TimeKeeper.set_date_of_record_unprotected!(Date.new(Date.today.year, 12, 15))
      effective_on = hbx_profile.benefit_sponsorship.current_benefit_period.start_on
      tax_household10 = FactoryBot.create(:tax_household, household: family.active_household, effective_ending_on: nil, effective_starting_on: hbx_profile.benefit_sponsorship.current_benefit_period.start_on)
      FactoryBot.create(:eligibility_determination, tax_household: tax_household10, max_aptc: 2000, determined_on: hbx_profile.benefit_sponsorship.current_benefit_period.start_on)
      tax_household10.tax_household_members.create(applicant_id: family.primary_applicant.id, is_subscriber: true, is_ia_eligible: true)
      tax_household10.tax_household_members.create(applicant_id: family.family_members[1].id, is_ia_eligible: true)
      @product = product
      service_area = ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: effective_on.year).first || FactoryBot.create_default(:benefit_markets_locations_service_area, active_year: effective_on.year)
      @product.update_attributes(ehb: 0.9844, application_period: Date.new(effective_on.year, 1, 1)..Date.new(effective_on.year, 1, 1).end_of_year, service_area_id: service_area.id)
      premium_table = @product.premium_tables.first
      premium_table.update_attributes(effective_period: Date.new(effective_on.year, 1, 1)..Date.new(effective_on.year, 1, 1).end_of_year)
      @product.save!
      enrollment.update_attributes(product: @product, effective_on: effective_on, aasm_state: "coverage_selected")
      hbx_profile.benefit_sponsorship.benefit_coverage_periods.each {|bcp| bcp.update_attributes!(slcsp_id: @product.id)}
      ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
      cr1 = FactoryBot.build(:consumer_role, :contact_method => "Paper Only")
      family.family_members[1].person.consumer_role = cr1
      cr2 = FactoryBot.build(:consumer_role, :contact_method => "Paper Only")
      family.family_members[2].person.consumer_role = cr2

      family.save!

      allow(::Operations::PremiumCredits::FindAptc).to receive(:new).and_return(
        double(
          call: double(
            success?: true,
            value!: max_aptc
          )
        )
      )
      allow(UnassistedPlanCostDecorator).to receive(:new).and_return(double(total_ehb_premium: 1500, total_premium: 1600, total_childcare_subsidy_amount: 0))
    end

    let(:max_aptc) { 1200.0 }

    context 'when elected_aptc_pct exists on previous enrollment' do
      it 'returns new enrollment with newly determined aptc' do
        enrollment.update_attributes(elected_aptc_pct: 0.85)
        subject.new.call({family: family, year: effective_date.year + 1})
        enrollment.reload
        expect(enrollment.aasm_state).to eq 'coverage_canceled'
        new_enrollment = family.reload.active_household.hbx_enrollments.last
        expect(new_enrollment.aggregate_aptc_amount.to_f).to eq(max_aptc)
        expect(new_enrollment.elected_aptc_pct).to eq(0.85)
        expect(new_enrollment.applied_aptc_amount.to_f).to eq(1020.0)
        expect(new_enrollment.ehb_premium.to_f).to eq(1500.0)
      end
    end

    context 'when elected_aptc_pct not exists' do
      context 'when elected_aptc_pct '
      it 'creates enrollment with default elected_aptc_pct' do
        subject.new.call({family: family, year: effective_date.year + 1})
        new_enrollment = family.reload.active_household.hbx_enrollments.last
        expect(new_enrollment.aggregate_aptc_amount.to_f).to eq(max_aptc)
        expect(new_enrollment.elected_aptc_pct).to eq(1.0)
        expect(new_enrollment.applied_aptc_amount.to_f).to eq(1200.0)
        expect(new_enrollment.ehb_premium.to_f).to eq(1500.0)
      end
    end

    context 'when elected_aptc_pct is 0' do
      it 'creates enrollment with 0 for elected_aptc_pct' do
        enrollment.update_attributes(elected_aptc_pct: 0.0)
        subject.new.call({family: family, year: effective_date.year + 1})
        new_enrollment = family.reload.active_household.hbx_enrollments.last
        expect(new_enrollment.aggregate_aptc_amount.to_f).to eq(max_aptc)
        expect(new_enrollment.elected_aptc_pct).to eq(1.0)
        expect(new_enrollment.applied_aptc_amount.to_f).to eq(1200.0)
      end
    end

    context 'when ehb premium less than aptc' do
      before do
        hbx_profile.benefit_sponsorship.current_benefit_period.start_on
        allow(UnassistedPlanCostDecorator).to receive(:new).and_return(double(total_ehb_premium: 393.76, total_premium: 410, total_childcare_subsidy_amount: 16.24))
      end

      it 'creates enrollment with ehb premium' do
        subject.new.call({family: family, year: effective_date.year + 1})
        new_enrollment = family.reload.active_household.hbx_enrollments.last
        expect(new_enrollment.aggregate_aptc_amount.to_f).to eq(max_aptc)
        expect(new_enrollment.applied_aptc_amount.to_f).to eq(393.76)
        expect(new_enrollment.ehb_premium.to_f).to eq(393.76)
      end
    end
  end

  after(:all) do
    DatabaseCleaner.clean
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end
end
