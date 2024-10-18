require 'rails_helper'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe Admin::Aptc, :type => :model, dbclean: :after_each do
    before :each do
      allow(EnrollRegistry[:calculate_monthly_aggregate].feature).to receive(:is_enabled).and_return(false)
      allow(EnrollRegistry[:apply_aggregate_to_enrollment].feature).to receive(:is_enabled).and_return(false)
    end
    let(:months_array) {Date::ABBR_MONTHNAMES.compact}

    # Household
    let(:family)       { FactoryBot.create(:family, :with_primary_family_member) }
    let(:household) {FactoryBot.create(:household, family: family)}
    let(:tax_household) {FactoryBot.create(:tax_household, household: household, effective_starting_on: Date.new(TimeKeeper.date_of_record.year,1,1), effective_ending_on: nil)}
    let(:sample_max_aptc_1) {511.78}
    let(:sample_max_aptc_2) {612.33}
    let(:sample_csr_percent_1) {87}
    let(:sample_csr_percent_2) {94}
    let(:eligibility_determination_1) {EligibilityDetermination.new(determined_at: TimeKeeper.date_of_record.beginning_of_year, max_aptc: sample_max_aptc_1, csr_percent_as_integer: sample_csr_percent_1, source: 'Admin')}
    let(:eligibility_determination_2) {EligibilityDetermination.new(determined_at: TimeKeeper.date_of_record.beginning_of_year + 4.months, max_aptc: sample_max_aptc_2, csr_percent_as_integer: sample_csr_percent_2, source: 'Admin')}
    let(:product1) { FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01') }
    let(:product2) { FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01', ehb: 0.9939) }

    # Enrollments
    let!(:hbx_with_aptc_1) do
      FactoryBot.create(:hbx_enrollment,
                        product: product1,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'coverage_selected',
                        changing: false,
                        effective_on: (TimeKeeper.date_of_record.beginning_of_month - 40.days),
                        kind: "individual",
                        applied_aptc_amount: 100)
    end
    let!(:hbx_with_aptc_2) do
      FactoryBot.create(:hbx_enrollment,
                        product: product2,
                        family: family,
                        household: household,
                        is_active: true,
                        aasm_state: 'coverage_selected',
                        changing: false,
                        effective_on: (TimeKeeper.date_of_record.beginning_of_month + 10.days),
                        kind: "individual",
                        applied_aptc_amount: 210)
    end
    let!(:hbx_enrollments) {[hbx_with_aptc_1, hbx_with_aptc_2]}
    let(:hbx_enrollment_member_1){ FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: TimeKeeper.date_of_record.beginning_of_month, applied_aptc_amount: 70)}
    let(:hbx_enrollment_member_2){ FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: TimeKeeper.date_of_record.beginning_of_month, applied_aptc_amount: 30)}
    let(:year) {TimeKeeper.date_of_record.year}

    context "household_level aptc_csr data", dbclean: :after_each do

      before(:each) do
        allow(family).to receive(:active_household).and_return household
        allow(household).to receive(:latest_active_tax_household_with_year).and_return tax_household
        allow(eligibility_determination_1).to receive(:tax_household).and_return tax_household
        allow(eligibility_determination_2).to receive(:tax_household).and_return tax_household
        tax_household.eligibility_determinations << [eligibility_determination_1, eligibility_determination_2]
        tax_household.save!
        TimeKeeper.set_date_of_record_unprotected!(Date.new(TimeKeeper.date_of_record.year, 6, 10))
      end

      after(:all) do
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
      end

      # MAX APTC
      context "build max_aptc values" do
        let(:expected_hash_without_param_case)  do
          {"Jan" => "511.78", "Feb" => "511.78", "Mar" => "511.78", "Apr" => "511.78", "May" => "612.33", "Jun" => "612.33",
           "Jul" => "612.33", "Aug" => "612.33", "Sep" => "612.33", "Oct" => "612.33", "Nov" => "612.33", "Dec" => "612.33" }
        end

        let(:expected_hash_with_param_case)     do
          {"Jan" => "511.78", "Feb" => "511.78", "Mar" => "511.78", "Apr" => "511.78", "May" => "612.33", "Jun" => "666.00",
           "Jul" => "666.00", "Aug" => "666.00", "Sep" => "666.00", "Oct" => "666.00", "Nov" => "666.00", "Dec" => "666.00"}
        end

        it "should return a hash that reflects max_aptc change on a montly basis based on the determined_at date of eligibility determinations - without max_aptc param" do
          expect(Admin::Aptc.build_max_aptc_values(year, family, nil)).to eq expected_hash_without_param_case
        end

        # This 'change in param' case is for the AJAX call where the latest max_aptc is not read from the latest ED from the database but read from a user input - transient"
        it "should return a hash that reflects max_aptc change on a montly basis based on the determined_at date of eligibility determinations - with max_aptc param" do
          expect(Admin::Aptc.build_max_aptc_values(year, family, 666)).to eq expected_hash_with_param_case
        end
      end

      # CSR PERCENT AS INTEGER
      context "build csr_percentage values" do

        let(:expected_hash_without_param_case)  { {"Jan" => 87, "Feb" => 87, "Mar" => 87, "Apr" => 87, "May" => 94, "Jun" => 94, "Jul" => 94, "Aug" => 94, "Sep" => 94, "Oct" => 94, "Nov" => 94, "Dec" => 94} }
        let(:expected_hash_with_param_case)     { {"Jan" => 87, "Feb" => 87, "Mar" => 87, "Apr" => 87, "May" => 94, "Jun" => 100, "Jul" => 100, "Aug" => 100, "Sep" => 100, "Oct" => 100, "Nov" => 100, "Dec" => 100} }

        it "should return a hash that reflects csr_percent change on a montly basis based on the determined_at date of eligibility determinations - without csr_percent param" do
          expect(Admin::Aptc.build_csr_percentage_values(year, family, nil)).to eq expected_hash_without_param_case
        end

        it "should return a hash that reflects csr_percent change on a montly basis based on the determined_at date of eligibility determinations - with csr_percent param" do
          expect(Admin::Aptc.build_csr_percentage_values(year, family, 100)).to eq expected_hash_with_param_case
        end
      end

      # REDETERMINE ELIGIBILITY
      context "redetermine_eligibility_with_updated_values" do
        let(:params) { {"max_aptc" => "27.00", "csr_percentage" => "73", "commit" => "Update"} }

        it "should save a new determination when the Max APTC / CSR is updated" do
          expect(Admin::Aptc.redetermine_eligibility_with_updated_values(family, params, [], year)).to eq true
        end
      end
    end

    # UPDATE APPLIED APTC  TO AN ENROLLMENT!
    context "update_aptc_applied_for_enrollments", dbclean: :after_each do
      let(:params) do
        {
          "person" => { "person_id" => family.primary_applicant.person.id, "family_id" => family.id, "current_year" => TimeKeeper.date_of_record.year},
          "max_aptc" => "100.00",
          "csr_percentage" => "0",
          "applied_pct_#{hbx_with_aptc_2.id}" => "0.85",
          "aptc_applied_#{hbx_with_aptc_2.id}" => "85.00"
        }
      end

      before do
        allow(TimeKeeper).to receive(:datetime_of_record).and_return(DateTime.new(TimeKeeper.date_of_record.year, 11, 1))
      end

      after do
        allow(TimeKeeper).to receive(:date_of_record).and_call_original
      end

      it "should create a new enrollment with a new hbx_id" do
        allow(family).to receive(:active_household).and_return household
        allow(household).to receive(:latest_active_tax_household_with_year).and_return tax_household
        allow(tax_household).to receive(:latest_eligibility_determination).and_return eligibility_determination_1
        enrollment_count = family.active_household.hbx_enrollments.count
        last_enrollment = family.active_household.hbx_enrollments.last
        expect(Admin::Aptc.update_aptc_applied_for_enrollments(family, params, year)).to eq true
        expect(family.active_household.hbx_enrollments.count).to eq enrollment_count + 1
        expect(last_enrollment.hbx_id).to_not eq family.active_household.hbx_enrollments.last.id
      end

      it "should create a new enrollment and should apply ehb aptc to enrollment" do
        allow(family).to receive(:active_household).and_return household
        allow(household).to receive(:latest_active_tax_household_with_year).and_return tax_household
        allow(tax_household).to receive(:latest_eligibility_determination).and_return eligibility_determination_1
        enrollment_count = family.active_household.hbx_enrollments.count
        last_enrollment = family.active_household.hbx_enrollments.last
        expect(Admin::Aptc.update_aptc_applied_for_enrollments(family, params, year)).to eq true
        expect(family.active_household.hbx_enrollments.count).to eq enrollment_count + 1
        expect(last_enrollment.hbx_id).to_not eq family.active_household.hbx_enrollments.last.id
        expect(family.active_household.hbx_enrollments.last.applied_aptc_amount.to_f).not_to eq 85
        expect(family.reload.hbx_enrollments.last.aggregate_aptc_amount.to_f).not_to be_zero
      end
    end

    context "years_with_tax_household", dbclean: :after_each do
      let(:past_date) { Date.new(oe_start_year, 10, 10) }
      let(:future_date) { Date.new(oe_start_year + 1, 10, 10) }
      let!(:family10) { FactoryBot.create(:family, :with_primary_family_member) }
      let!(:tax_household10) { FactoryBot.create(:tax_household, household: family10.households.first, effective_starting_on: past_date, effective_ending_on: nil) }
      let!(:hbx_profile) { FactoryBot.create(:hbx_profile, :single_open_enrollment_coverage_period) }
      let!(:current_hbx_under_open_enrollment) {double("current hbx", under_open_enrollment?: true)}
      let(:oe_start_year) { Settings.aca.individual_market.open_enrollment.start_on.year }

      context "when open_enrollment after Dec 31st" do
        before :each do
          TimeKeeper.set_date_of_record_unprotected!(future_date)
        end

        after :each do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        it "should return array without next year added as it is not under_open_enrollment" do
          tax_household10.update_attributes!(effective_starting_on: future_date)
          expect(Admin::Aptc.years_with_tax_household(family10)).to eq [future_date.year]
        end
      end

      context "when open_enrollment on or before Dec 31st" do
        before :each do
          TimeKeeper.set_date_of_record_unprotected!(past_date)
        end

        after :each do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        it "should return array with next year added as it is under_open_enrollment" do
          allow(HbxProfile).to receive(:current_hbx).and_return(current_hbx_under_open_enrollment)
          expect(Admin::Aptc.years_with_tax_household(family10)).to eq [past_date.year, past_date.year + 1]
        end

        it "should return array without next year added as it is not under_open_enrollment" do
          allow(HbxProfile).to receive(:current_hbx).and_return(false)
          expect(Admin::Aptc.years_with_tax_household(family10)).to eq [past_date.year]
        end
      end
    end

    context 'calculate_slcsp_value', dbclean: :after_each do
      let!(:rating_area_5) do
        ::BenefitMarkets::Locations::RatingArea.rating_area_for(rating_address, during: effective_on) || FactoryBot.create_default(:benefit_markets_locations_rating_area)
      end
      let(:rating_address) { family_5.primary_person.consumer_role.rating_address }
      let!(:service_area_5) do
        ::BenefitMarkets::Locations::ServiceArea.service_areas_for(rating_address, during: effective_on)[0] || FactoryBot.create_default(:benefit_markets_locations_service_area)
      end
      let!(:person) {FactoryBot.create(:person, :with_consumer_role)}
      let!(:family_5) {FactoryBot.create(:family, :with_primary_family_member, person: person, e_case_id: "family_test#1000")}
      let!(:person2) do
        member = FactoryBot.create(:person, :with_consumer_role, dob: (TimeKeeper.date_of_record - 40.years))
        person.ensure_relationship_with(member, 'spouse')
        member.save!
        member
      end
      let!(:family_member2) {FactoryBot.create(:family_member, family: family_5, person: person2)}
      let(:effective_on) { Date.new(TimeKeeper.date_of_record.year, 11, 1) }
      let!(:tax_household_5) {FactoryBot.create(:tax_household, household: family_5.active_household, effective_ending_on: nil, effective_starting_on: effective_on)}
      let!(:tax_household_member1) {FactoryBot.create(:tax_household_member, applicant_id: family_5.family_members[0].id, tax_household: tax_household_5)}
      let!(:tax_household_member2) {FactoryBot.create(:tax_household_member, applicant_id: family_member2.id, tax_household: tax_household_5)}

      let!(:premium_table) { build(:benefit_markets_products_premium_table, effective_period: application_period, rating_area: rating_area_5) }
      let!(:product) do
        product = FactoryBot.create(
          :benefit_markets_products_health_products_health_product,
          :with_issuer_profile,
          benefit_market_kind: :aca_individual,
          kind: :health,
          service_area: service_area_5,
          csr_variant_id: '01',
          metal_level_kind: :silver,
          application_period: application_period
        )
        product.premium_tables = [premium_table]
        product.save
        product
      end

      let(:application_period) {effective_on.beginning_of_year..effective_on.end_of_year}

      before do
        ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
      end

      it "should calculate slcsp value" do
        expect(Admin::Aptc.calculate_slcsp_value(TimeKeeper.date_of_record.year, family_5)).to eq '400.00'
      end
    end
  end
end
