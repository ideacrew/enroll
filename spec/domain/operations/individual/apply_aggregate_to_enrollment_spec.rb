# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Individual::ApplyAggregateToEnrollment, dbclean: :after_each do

  context 'for invalid params' do
    it 'should return a failure with a message' do
      expect(subject.call({eligibility_determination: 'eligibility_determination'}).failure).to eq('Given object is not a valid eligibility determination object')
    end
  end

  let!(:plan) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')}

  let!(:rating_area) do
    ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: start_on) || FactoryBot.create_default(:benefit_markets_locations_rating_area)
  end
  let!(:service_area) do
    ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: start_on).first || FactoryBot.create_default(:benefit_markets_locations_service_area)
  end
  let(:application_period) { start_on.beginning_of_year..start_on.end_of_year }
  let!(:plan) do
    prod =
      FactoryBot.create(
        :benefit_markets_products_health_products_health_product,
        :with_issuer_profile,
        benefit_market_kind: :aca_individual,
        kind: :health,
        service_area: service_area,
        csr_variant_id: '01',
        metal_level_kind: 'silver',
        application_period: application_period
      )
    prod.premium_tables = [premium_table]
    prod.save
    prod
  end
  let(:premium_table)        { build(:benefit_markets_products_premium_table, effective_period: application_period, rating_area: rating_area) }

  let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
  let!(:person) {FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
  let(:address) { person.rating_address }
  let(:consumer_role) { person.consumer_role }
  let!(:family) {FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person)}
  let!(:primary_fm) {family.primary_applicant}
  let!(:household) {family.active_household}
  let!(:start_on) {TimeKeeper.date_of_record.beginning_of_year}
  let(:family_member1) {family.family_members[1]}
  let!(:tax_household) do
    tax_household = FactoryBot.create(:tax_household, effective_ending_on: nil, household: family.households.first)
    FactoryBot.create(:tax_household_member, tax_household: tax_household, applicant_id: family_member1.id, is_ia_eligible: true)
    tax_household
  end
  let(:sample_max_aptc_1) {1200}
  let(:sample_csr_percent_1) {87}
  let!(:eligibility_determination) {FactoryBot.create(:eligibility_determination, tax_household: tax_household, max_aptc: sample_max_aptc_1, csr_percent_as_integer: sample_csr_percent_1)}
  let!(:product1) do
    prod =
      FactoryBot.create(
        :benefit_markets_products_health_products_health_product,
        :with_issuer_profile,
        benefit_market_kind: :aca_individual,
        kind: :health,
        service_area: service_area,
        csr_variant_id: '01',
        metal_level_kind: 'silver',
        application_period: application_period
      )
    prod.premium_tables = [premium_table1]
    prod.save
    prod
  end
  let(:premium_table1)        { build(:benefit_markets_products_premium_table, effective_period: application_period, rating_area: rating_area) }

  let(:hbx_with_aptc_1) do
    enr = FactoryBot.create(:hbx_enrollment,
                            product: product1,
                            family: family,
                            household: household,
                            is_active: true,
                            aasm_state: 'coverage_selected',
                            changing: false,
                            effective_on: start_on,
                            kind: "individual",
                            applied_aptc_amount: 100,
                            rating_area_id: rating_area.id,
                            consumer_role_id: consumer_role.id,
                            elected_aptc_pct: 0.7)
    FactoryBot.create(:hbx_enrollment_member, applicant_id: family_member1.id, hbx_enrollment: enr)
    enr
  end
  let!(:hbx_enrollments) {[hbx_with_aptc_1]}

  let!(:consumer_role1) do
    cr = FactoryBot.build(:consumer_role, :contact_method => "Paper Only")
    family.family_members[1].person.consumer_role = cr
    family.family_members[1].person.save!
  end

  let!(:consumer_role2) do
    cr = FactoryBot.build(:consumer_role, :contact_method => "Paper Only")
    family.family_members[2].person.consumer_role = cr
    family.family_members[2].person.save!
  end

  before(:each) do
    allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate) {|_id, _start, age| age * 1.0}
    hbx_profile.benefit_sponsorship.benefit_coverage_periods.detect {|bcp| bcp.contains?(start_on)}.update_attributes!(slcsp_id: plan.id)
  end

  context 'return failure with no active tax household' do
    before do
      allow(eligibility_determination).to receive(:tax_household).and_return nil
      input_params = {eligibility_determination: eligibility_determination}
      @result = subject.call(input_params)
    end

    it 'should return monthly aggregate amount' do
      expect(@result.failure).to eq('No active tax household for given eligibility')
    end
  end

  context 'passing params with catastrophic plans' do
    before do
      hbx_with_aptc_1.product.update_attributes(metal_level_kind: 'catastrophic')
      input_params = {eligibility_determination: eligibility_determination}
      @result = subject.call(input_params)
    end

    it 'should not apply aggregate amount' do
      expect(@result.failure).to eq('Cannot find any enrollments with Non-Catastrophic Plan.')
    end
  end

  context 'when eligibility is created for year with no active enrollments' do
    before do
      tax_household.update_attributes(effective_starting_on: tax_household.effective_starting_on.next_year)
      input_params = {eligibility_determination: eligibility_determination}
      @result = subject.call(input_params)
    end

    it 'should not apply aggregate' do
      expect(@result.failure).to eq('Cannot find any IVL health enrollments in any of the active states.')
    end
  end

  context 'apply aggregate on eligible enrollments' do
    before(:each) do
      allow(TimeKeeper).to receive(:date_of_record).and_return Date.new(start_on.year, 1, 26)
      allow(family).to receive(:active_household).and_return(household)
    end

    it 'returns monthly aggregate amount' do
      input_params = {eligibility_determination: eligibility_determination}
      @result = subject.call(input_params)
      expect(@result.success).to eq "Aggregate amount applied on to enrollments"
      expect(family.hbx_enrollments.to_a.first.applied_aptc_amount).not_to eq family.hbx_enrollments.last.applied_aptc_amount
    end

    context 'enrollment the is auto-renewal enrollment' do
      before do
        hbx_with_aptc_1.update_attributes(aasm_state: 'auto_renewing')
      end

      it 'returns monthly aggregate amount' do
        expect(family.hbx_enrollments.to_a.count).to eq 1
        input_params = {eligibility_determination: eligibility_determination}
        @result = subject.call(input_params)
        expect(@result.success).to eq 'Aggregate amount applied on to enrollments'
        family.reload
        expect(family.hbx_enrollments.to_a.count).to eq 2
      end
    end
  end

  context 'when previous tax_household does not have the same thhm as present one' do
    let!(:new_tax_household) do
      new_tax_household = FactoryBot.create(:tax_household, created_at: (tax_household.created_at + 1.day), effective_starting_on: (tax_household.effective_starting_on + 10.day), effective_ending_on: nil, household: family.households.first)
      FactoryBot.create(:tax_household_member, tax_household: new_tax_household, applicant_id: family_member1.id, is_ia_eligible: true)
      new_tax_household
    end
    let(:new_sample_max_aptc_1) {1500}
    let(:new_sample_csr_percent_1) {87}
    let!(:new_eligibility_determination) {FactoryBot.create(:eligibility_determination, tax_household: new_tax_household, max_aptc: new_sample_max_aptc_1, csr_percent_as_integer: new_sample_csr_percent_1)}

    before do
      tax_household.update_attributes(effective_ending_on: new_tax_household.effective_starting_on - 1.day)
      tax_household.tax_household_members.first.update_attributes(is_ia_eligible: false)
    end

    it 'returns monthly aggregate amount' do
      input_params = {eligibility_determination: new_eligibility_determination}
      @result = subject.call(input_params)
      expect(@result.success).to eq "Aggregate amount applied on to enrollments"
      expect(family.hbx_enrollments.to_a.first.applied_aptc_amount).not_to eq family.hbx_enrollments.last.applied_aptc_amount
    end
  end

  context 'prospective year enrollment' do
    before(:each) do
      current_year = Date.today.year
      system_date = rand(Date.new(current_year, 11, 1)..Date.new(current_year, 12, 1))
      allow(TimeKeeper).to receive(:date_of_record).and_return(system_date)
      allow(family).to receive(:active_household).and_return(household)
      tax_household.update_attributes!(effective_starting_on: Date.today.next_year.beginning_of_year)
      hbx_with_aptc_1.update_attributes!(effective_on: Date.new(hbx_with_aptc_1.effective_on.next_year.year, 3, 1))
      new_app_period = Date.today.next_year.beginning_of_year..Date.today.next_year.end_of_year
      ::BenefitMarkets::Products::Product.each do |product|
        product.update_attributes!(application_period: new_app_period)
        product.premium_tables.each { |p_table| p_table.update_attributes!(effective_period: new_app_period) }
      end
      ::BenefitMarkets::Locations::RatingArea.update_all(active_year: current_year.next)
      ::BenefitMarkets::Locations::ServiceArea.update_all(active_year: current_year.next)
      @result = subject.call({ eligibility_determination: tax_household.reload.latest_eligibility_determination })
      @new_enrollment = hbx_with_aptc_1.family.reload.hbx_enrollments.last
    end

    it 'should return success' do
      expect(@result.success).to eq 'Aggregate amount applied on to enrollments'
    end

    it 'should return enrollment with effective_on as start of prospective year' do
      expect(@new_enrollment.effective_on).to eq(Date.today.next_year.beginning_of_year)
    end
  end
end
