# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UnassistedPlanCostDecorator, dbclean: :after_each do
  let(:exchange_provided_code) { 1 }
  let(:rating_area) { double(exchange_provided_code: exchange_provided_code) }
  let(:premium_table) { double(rating_area: rating_area) }
  let(:premium_tables) { [premium_table] }
  let!(:default_plan)            { double("Product", id: "default_plan_id", kind: "health", family_based_rating?: false, premium_tables: premium_tables) }
  let!(:dental_plan)             { double('Product', id: 'dental_plan_id', kind: :dental, family_based_rating?: false, premium_tables: premium_tables, ehb: 0.996) }
  let(:plan_cost_decorator)     { UnassistedPlanCostDecorator.new(plan, member_provider) }
  let(:area) { EnrollRegistry[:rating_area].settings(:areas).item.first }
  context "rating a large family" do
    let(:plan)            {default_plan}
    let(:consumer_role) { ConsumerRole.new }
    let(:rating_address) { FactoryBot.build(:address) }
    let!(:member_provider) {double("member_provider", effective_on: 10.days.ago, hbx_enrollment_members: [father, mother, one, two, three, four, five], consumer_role: consumer_role, rating_area: rating_area)}
    let!(:father)          {double("father", dob: 55.years.ago, age_on_effective_date: 55, employee_relationship: "self", tobacco_use: nil, is_subscriber?: true, primary_relationship: "self")}
    let!(:mother)          {double("mother", dob: 45.years.ago, age_on_effective_date: 45, employee_relationship: "spouse", tobacco_use: nil, is_subscriber?: false, primary_relationship: "spouse")}
    let!(:one)             {double("one", dob: 20.years.ago, age_on_effective_date: 20, employee_relationship: "child", tobacco_use: nil, is_subscriber?: false, primary_relationship: "child")}
    let!(:two)             {double("two", dob: 18.years.ago, age_on_effective_date: 18, employee_relationship: "child", tobacco_use: nil, is_subscriber?: false, primary_relationship: "child")}
    let!(:three)           {double("three", dob: 13.years.ago, age_on_effective_date: 13, employee_relationship: "child", tobacco_use: nil, is_subscriber?: false, primary_relationship: "child")}
    let!(:four)            {double("four", dob: 11.years.ago, age_on_effective_date: 11, employee_relationship: "child", tobacco_use: nil, is_subscriber?: false, primary_relationship: "child")}
    let!(:five)            {double("five", dob: 4.years.ago, age_on_effective_date: 4, employee_relationship: "child", tobacco_use: nil, is_subscriber?: false, primary_relationship: "child")}
    let!(:relationship_benefit_for) do
      { "self" => double("self", :offered? => true),
        "spouse" => double("spouse", :offered? => true),
        "child" => double("child", :offered? => true)}
    end

    before do
      allow(consumer_role).to receive(:rating_address).and_return(rating_address)
      allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate) {|_id, _start, age| age * 1.0}
    end

    it "should be possible to construct a new plan cost decorator" do
      expect(plan_cost_decorator.class).to be UnassistedPlanCostDecorator
    end

    it "should have a premium for father" do
      expect(plan_cost_decorator.premium_for(father)).to eq 55.0
    end

    it "should have a premium for mother" do
      expect(plan_cost_decorator.premium_for(mother)).to eq 45.0
    end

    it "should have a premium for one" do
      expect(plan_cost_decorator.premium_for(one)).to eq 20.0
    end

    it "should have a premium for two" do
      expect(plan_cost_decorator.premium_for(two)).to eq 18.0
    end

    it "should have a premium for three" do
      expect(plan_cost_decorator.premium_for(three)).to eq 13.0
    end

    it "should have no premium for four" do
      expect(plan_cost_decorator.premium_for(four)).to eq 0.0
    end

    it "should have no premium for five" do
      expect(plan_cost_decorator.premium_for(five)).to eq 0.0
    end

    it "should have the right total premium" do
      expect(plan_cost_decorator.total_premium).to eq [55, 45, 20, 18, 13].sum
    end

    context "with a dental plan" do
      let(:plan)            {dental_plan}
      it "should have a premium for four" do
        expect(plan_cost_decorator.premium_for(four)).to eq 11.0
      end

      it "should have a premium for five" do
        expect(plan_cost_decorator.premium_for(five)).to eq 4.0
      end

      it "should have the right total premium" do
        expect(plan_cost_decorator.total_premium).to eq [55, 45, 20, 18, 13, 11, 4].sum
      end

      context 'when total_minimum_responsibility is enabled' do
        before do
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate) {|_id, _start, age| age * 0.0}
          allow(EnrollRegistry[:total_minimum_responsibility].feature).to receive(:is_enabled).and_return(true)
        end

        it "should have the correct member ehb premium" do
          expect(plan_cost_decorator.member_ehb_premium(five)).to eq 0.00
        end
      end
    end
  end

  describe 'UnassistedPlanCostDecorator' do

    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let!(:family10) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person) }
    let!(:hbx_enrollment10) do
      FactoryBot.create(:hbx_enrollment, family: family10, household: family10.active_household, aasm_state: 'shopping', product: product, consumer_role_id: person.consumer_role.id, effective_on: TimeKeeper.date_of_record,
                                         rating_area_id: rating_area.id)
    end
    let!(:hbx_enrollment_member1) do
      FactoryBot.create(:hbx_enrollment_member, applicant_id: family10.primary_applicant.id, is_subscriber: true, eligibility_date: (TimeKeeper.date_of_record - 10.days), coverage_start_on: TimeKeeper.date_of_record, hbx_enrollment: hbx_enrollment10)
    end
    let!(:hbx_enrollment_member2) do
      FactoryBot.create(:hbx_enrollment_member, applicant_id: family10.family_members[1].id, eligibility_date: (TimeKeeper.date_of_record - 10.days), coverage_start_on: TimeKeeper.date_of_record, hbx_enrollment: hbx_enrollment10)
    end
    let!(:rating_area) do
      ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: effective_on) || FactoryBot.create_default(:benefit_markets_locations_rating_area, active_year: effective_on.year)
    end
    let!(:service_area) do
      ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: effective_on).first || FactoryBot.create_default(:benefit_markets_locations_service_area, active_year: effective_on.year)
    end
    let(:application_period) { TimeKeeper.date_of_record.beginning_of_year..TimeKeeper.date_of_record.end_of_year }
    let(:effective_on) { TimeKeeper.date_of_record.beginning_of_month }
    let!(:product) do
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

    let(:address) { person.rating_address }
    let!(:tax_household10) { FactoryBot.create(:tax_household, household: family10.active_household, effective_ending_on: nil) }
    let!(:eligibility_determination) { FactoryBot.create(:eligibility_determination, tax_household: tax_household10, max_aptc: 2000) }
    let!(:tax_household_member1) { tax_household10.tax_household_members.create(applicant_id: family10.primary_applicant.id, is_subscriber: true, is_ia_eligible: true)}
    let!(:tax_household_member2) {tax_household10.tax_household_members.create(applicant_id: family10.family_members[1].id, is_ia_eligible: true)}
    let!(:hbx_profile) { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period) }
    let(:person2) { family10.family_members[1].person }
    let(:area) { rating_area.exchange_provided_code }

    before :each do
      @product = product
      @product.update_attributes(ehb: 0.9844)
      premium_table = @product.premium_tables.first
      premium_table.premium_tuples.where(age: 59).first.update_attributes(cost: 814.85)
      premium_table.premium_tuples.where(age: 60).first.update_attributes(cost: 846.72)
      premium_table.premium_tuples.where(age: 61).first.update_attributes(cost: 879.8)
      @product.save!
      ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
    end

    context 'for valid arguments' do
      before do
        person.update_attributes!(dob: (hbx_enrollment10.effective_on - 61.years))
        person2.update_attributes!(dob: (hbx_enrollment10.effective_on - 59.years))
      end

      context 'for persisted enrollment object' do
        context 'when elected aptc more than ehb premium, should rounddown on premium' do
          before :each do
            @upcd_1 = UnassistedPlanCostDecorator.new(@product, hbx_enrollment10, 1700.00, tax_household10)
          end

          it 'should return amounts based on member 1 age' do
            expect(@upcd_1.aptc_amount(hbx_enrollment_member1)).to eq 866.07
          end

          it 'should return amounts based on member 2 age' do
            expect(@upcd_1.aptc_amount(hbx_enrollment_member2)).to eq 802.13
          end

          it 'should return total_aptc_amount' do
            expect(@upcd_1.total_aptc_amount).to eq 1668.2
          end
        end

        context 'when elected aptc less than ehb premium, no rounding on premium' do
          before :each do
            @upcd_2 = UnassistedPlanCostDecorator.new(@product, hbx_enrollment10, 1500.00, tax_household10)
          end

          it 'should return amounts based on member 1 age' do
            expect(@upcd_2.aptc_amount(hbx_enrollment_member1)).to eq 778.7465531710825
          end

          it 'should return amounts based on member 2 age' do
            expect(@upcd_2.aptc_amount(hbx_enrollment_member2)).to eq 721.2534468289174
          end

          it 'should return total_aptc_amount' do
            expect(@upcd_2.total_aptc_amount).to eq 1500
          end
        end

        context 'when no premium but allocated aptc ratio for the member is present' do
          before :each do
            @upcd_2 = UnassistedPlanCostDecorator.new(@product, hbx_enrollment10, 1500.00, tax_household10)
            age = @upcd_2.age_of(hbx_enrollment_member1)
          end

          it 'should return the aptc amount of the member from individual member aptc hash' do
            expect(@upcd_2.aptc_amount(hbx_enrollment_member1)).to eq @upcd_2.all_members_aptc[hbx_enrollment_member1.applicant_id.to_s]
          end
        end
      end

      context "should have correct total_employee_cost" do
        let(:plan_cost_decorator) { UnassistedPlanCostDecorator.new(@product, hbx_enrollment10, 1500.00, tax_household10) }

        it "if multi taxhousehold feature is disabled" do
          total_cost = hbx_enrollment10.hbx_enrollment_members.collect do |member|
            plan_cost_decorator.employee_cost_for(member).round(2)
          end.compact.sum.round(2)

          expect(plan_cost_decorator.total_employee_cost).to eq total_cost
        end

        it "if multi taxhousehold feature is enabled" do
          allow(EnrollRegistry[:temporary_configuration_enable_multi_tax_household_feature].feature).to receive(:is_enabled).and_return(true)
          total_premium = plan_cost_decorator.total_premium
          total_aptc_amount = plan_cost_decorator.total_aptc_amount
          expect(plan_cost_decorator.total_employee_cost).to eq(total_premium - total_aptc_amount)
        end
      end

      context 'employee_cost_for member' do
        context 'when premium for member is zero and large family factor is zero' do
          before :each do
            @upcd_2 = UnassistedPlanCostDecorator.new(@product, hbx_enrollment10, 1500.00, tax_household10)
            allow(@upcd_2).to receive(:premium_for).with(hbx_enrollment_member1).and_return(0.0)
            allow(@upcd_2).to receive(:aptc_amount).with(hbx_enrollment_member1).and_return(100.0)
            allow(@upcd_2).to receive(:large_family_factor).with(hbx_enrollment_member1).and_return(0.0)
          end

          it 'should return the negative aptc amount of the member from individual member aptc hash' do
            expect(@upcd_2.employee_cost_for(hbx_enrollment_member1)).to eq(- @upcd_2.aptc_amount(hbx_enrollment_member1))
          end
        end

        context 'when premium for member is not zero and large family factor is zero' do
          before :each do
            @upcd_2 = UnassistedPlanCostDecorator.new(@product, hbx_enrollment10, 1500.00, tax_household10)
            allow(@upcd_2).to receive(:premium_for).with(hbx_enrollment_member1).and_return(100.0)
            allow(@upcd_2).to receive(:aptc_amount).with(hbx_enrollment_member1).and_return(10.0)
            allow(@upcd_2).to receive(:large_family_factor).with(hbx_enrollment_member1).and_return(0.0)
          end

          it 'should return the difference between premium and aptc amount of the member from individual member aptc hash' do
            expect(@upcd_2.employee_cost_for(hbx_enrollment_member1)).to eq 0.0
          end
        end

        context 'when premium for member is not zero and large family factor is 1.0' do
          before :each do
            @upcd_2 = UnassistedPlanCostDecorator.new(@product, hbx_enrollment10, 1500.00, tax_household10)
            allow(@upcd_2).to receive(:premium_for).with(hbx_enrollment_member1).and_return(100.0)
            allow(@upcd_2).to receive(:aptc_amount).with(hbx_enrollment_member1).and_return(10.0)
            allow(@upcd_2).to receive(:large_family_factor).with(hbx_enrollment_member1).and_return(1.0)
          end

          it 'should return the difference between premium and aptc amount of the member from individual member aptc hash' do
            expect(@upcd_2.employee_cost_for(hbx_enrollment_member1)).to eq(@upcd_2.premium_for(hbx_enrollment_member1) - @upcd_2.aptc_amount(hbx_enrollment_member1))
          end
        end

        context 'when premium for member is zero and large family factor is 1.0' do
          before :each do
            @upcd_2 = UnassistedPlanCostDecorator.new(@product, hbx_enrollment10, 1500.00, tax_household10)
            allow(@upcd_2).to receive(:premium_for).with(hbx_enrollment_member1).and_return(0.0)
            allow(@upcd_2).to receive(:aptc_amount).with(hbx_enrollment_member1).and_return(10.0)
            allow(@upcd_2).to receive(:large_family_factor).with(hbx_enrollment_member1).and_return(1.0)
          end

          it 'should return 0.0' do
            expect(@upcd_2.employee_cost_for(hbx_enrollment_member1)).to eq 0.0
          end
        end
      end

      context 'should have correct total_childcare_subsidy_amount' do
        let(:plan_cost_decorator) { UnassistedPlanCostDecorator.new(@product, hbx_enrollment10, 1500.00, tax_household10) }

        it 'for non hc4cc plan subsidy amount should be 0' do
          expect(plan_cost_decorator.total_childcare_subsidy_amount).to eq 0.0
        end

        context "for hc4cc plan" do
          before do
            allow(plan_cost_decorator).to receive(:is_eligible_for_osse_grant?).and_return true
            allow(plan_cost_decorator).to receive(:is_hc4cc_plan).and_return true
          end

          it 'for hc4cc plan subsidy amount should not be 0' do
            expect(plan_cost_decorator.total_childcare_subsidy_amount).not_to eq 0.0
          end
        end
      end

      context 'when elected aptc is 0, use method total_ehb_premium' do
        it 'should return total_ehb_premium' do
          upcd = UnassistedPlanCostDecorator.new(@product, hbx_enrollment10, 0.00, tax_household10)
          expect(upcd.total_ehb_premium).to eq 1668.2
        end
      end

      context 'for non-persisted enrollment object' do
        let(:current_date) {TimeKeeper.date_of_record}
        let!(:enrollment1) do
          FactoryBot.build(:hbx_enrollment, family: family10, household: family10.active_household, aasm_state: 'shopping', product: @product, consumer_role_id: person.consumer_role.id, effective_on: current_date, rating_area_id: rating_area.id)
        end
        let!(:enr_member1) { FactoryBot.build(:hbx_enrollment_member, applicant_id: family10.primary_applicant.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record, hbx_enrollment: enrollment1, coverage_start_on: current_date) }
        let!(:enr_member2) { FactoryBot.build(:hbx_enrollment_member, applicant_id: family10.family_members[1].id, eligibility_date: TimeKeeper.date_of_record, hbx_enrollment: enrollment1, coverage_start_on: current_date) }

        context 'when elected aptc more than ehb premium, should rounddown on premium' do
          before :each do
            @upcd_3 = UnassistedPlanCostDecorator.new(@product, enrollment1, 1700.00, tax_household10)
          end

          it 'should return amounts based on member 1 age' do
            expect(@upcd_3.aptc_amount(enr_member1)).to eq 866.07
          end

          it 'should return amounts based on member 2 age' do
            expect(@upcd_3.aptc_amount(enr_member2)).to eq 802.13
          end

          it 'should return total_aptc_amount' do
            expect(@upcd_3.total_aptc_amount).to eq 1668.2
          end
        end

        context 'when elected aptc less than ehb premium, no rounding on premium' do
          before :each do
            @upcd_4 = UnassistedPlanCostDecorator.new(@product, enrollment1, 1500.00, tax_household10)
          end

          it 'should return amounts based on member 1 age' do
            expect(@upcd_4.aptc_amount(enr_member1)).to eq 778.7465531710825
          end

          it 'should return amounts based on member 2 age' do
            expect(@upcd_4.aptc_amount(enr_member2)).to eq 721.2534468289174
          end

          it 'should return total_aptc_amount' do
            expect(@upcd_4.total_aptc_amount).to eq 1500
          end
        end
      end
    end

    context 'for invalid arguments' do
      let(:unassisted_plan_cost_decorator2) { UnassistedPlanCostDecorator.new(@product, hbx_enrollment10) }

      it 'should return 0.00 when invalid information is given' do
        expect(unassisted_plan_cost_decorator2.aptc_amount(hbx_enrollment_member1)).to eq 0.00
      end
    end

    context 'for uqhp case' do
      before do
        family10.active_household.tax_households.destroy_all
        family10.active_household.reload
      end

      it 'should return 0.00 as this is a uqhp case' do
        unassisted_plan_cost_decorator = UnassistedPlanCostDecorator.new(@product, hbx_enrollment10)
        expect(unassisted_plan_cost_decorator.aptc_amount(hbx_enrollment_member1)).to eq 0.00
      end
    end

    context 'large_family_factor for dental kind' do
      let!(:dental_product) { FactoryBot.create(:benefit_markets_products_dental_products_dental_product, :with_issuer_profile) }
      let!(:hbx_enrollment10) { FactoryBot.create(:hbx_enrollment, family: family10, household: family10.active_household, aasm_state: 'shopping', product: dental_product, rating_area_id: rating_area.id) }
      let!(:hbx_enrollment_member1) { FactoryBot.create(:hbx_enrollment_member, applicant_id: family10.primary_applicant.id, is_subscriber: true, eligibility_date: (TimeKeeper.date_of_record - 10.days), hbx_enrollment: hbx_enrollment10) }
      let!(:hbx_enrollment_member2) { FactoryBot.create(:hbx_enrollment_member, applicant_id: family10.family_members[1].id, eligibility_date: (TimeKeeper.date_of_record - 10.days), hbx_enrollment: hbx_enrollment10) }
      let(:unassisted_plan_cost_decorator_dental) { UnassistedPlanCostDecorator.new(dental_product, hbx_enrollment10) }

      it 'should return 1 for dental kind' do
        expect(unassisted_plan_cost_decorator_dental.large_family_factor(hbx_enrollment_member1)).to eq 1
      end
    end
  end

  describe 'ehb premiums' do
    let!(:rating_area) do
      ::BenefitMarkets::Locations::RatingArea.rating_area_for(address, during: effective_on) || FactoryBot.create_default(:benefit_markets_locations_rating_area, active_year: effective_on.year)
    end
    let!(:service_area) do
      ::BenefitMarkets::Locations::ServiceArea.service_areas_for(address, during: effective_on).first || FactoryBot.create_default(:benefit_markets_locations_service_area, active_year: effective_on.year)
    end
    let(:application_period) { TimeKeeper.date_of_record.beginning_of_year..TimeKeeper.date_of_record.end_of_year }
    let(:effective_on) { TimeKeeper.date_of_record.beginning_of_month }
    let!(:product) do
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

    let(:address) { person.rating_address }
    let(:person) {FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
    let!(:family10) {FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person)}
    let!(:hbx_enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        family: family10,
        household: family10.active_household,
        aasm_state: 'shopping',
        product: product,
        consumer_role_id: person.consumer_role.id,
        rating_area_id: rating_area.id,
        effective_on: TimeKeeper.date_of_record.beginning_of_month
      )
    end
    let!(:hbx_enrollment_member1) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family10.primary_applicant.id, is_subscriber: true, eligibility_date: (TimeKeeper.date_of_record - 10.days), hbx_enrollment: hbx_enrollment)}
    let!(:hbx_enrollment_member2) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family10.family_members[1].id, eligibility_date: (TimeKeeper.date_of_record - 10.days), hbx_enrollment: hbx_enrollment)}
    let!(:tax_household10) {FactoryBot.create(:tax_household, household: family10.active_household, effective_ending_on: nil)}
    let!(:eligibility_determination) {FactoryBot.create(:eligibility_determination, tax_household: tax_household10, max_aptc: 2000)}
    let!(:tax_household_member1) {tax_household10.tax_household_members.create(applicant_id: family10.primary_applicant.id, is_subscriber: true, is_ia_eligible: true)}
    let!(:tax_household_member2) {tax_household10.tax_household_members.create(applicant_id: family10.family_members[1].id, is_ia_eligible: true)}
    let!(:hbx_profile) {FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period)}
    let(:person2) {family10.family_members[1].person}
    let(:rating_area) { FactoryBot.create(:benefit_markets_locations_rating_area) }
    let(:area) { rating_area.exchange_provided_code }

    before :each do
      @product = product
      @product.update_attributes(ehb: 0.9844)
      premium_table = @product.premium_tables.first
      premium_table.premium_tuples.where(age: 59).first.update_attributes(cost: 814.85)
      premium_table.premium_tuples.where(age: 60).first.update_attributes(cost: 846.72)
      premium_table.premium_tuples.where(age: 61).first.update_attributes(cost: 879.8)
      @product.save!
      ::BenefitMarkets::Products::ProductRateCache.initialize_rate_cache!
      person.update_attributes!(dob: (hbx_enrollment.effective_on - 61.years))
      person2.update_attributes!(dob: (hbx_enrollment.effective_on - 59.years))
      @upcd_1 = UnassistedPlanCostDecorator.new(@product, hbx_enrollment, 1700.00, tax_household10)
    end

    context 'for total_ehb_premium' do
      it 'should return some valid amount when valid information is given' do
        expect(@upcd_1.total_ehb_premium).to eq 1668.2
      end

      context 'when mthh enabled' do
        before do
          allow(EnrollRegistry[:temporary_configuration_enable_multi_tax_household_feature].feature).to receive(:is_enabled).and_return(true)
        end

        context 'when grants does not exist' do
          it 'returns ehb premium by considering all the members' do
            expect(@upcd_1.total_ehb_premium).to eq 1668.2
          end
        end

        context 'when grants exists' do

          let(:tax_household) do
            tax_household_group.tax_households.first
          end

          let!(:tax_household_group) do
            family10.tax_household_groups.create!(
              assistance_year: TimeKeeper.date_of_record.year,
              source: 'Admin',
              start_on: TimeKeeper.date_of_record.beginning_of_year,
              tax_households: [
                FactoryBot.build(:tax_household, household: family10.active_household)
              ]
            )
          end

          context 'grants exists for all members' do
            let!(:eligibility_determination) do
              determination = family10.create_eligibility_determination(effective_date: TimeKeeper.date_of_record.beginning_of_year)
              determination.grants.create(
                key: "AdvancePremiumAdjustmentGrant",
                value: 1000,
                start_on: TimeKeeper.date_of_record.beginning_of_year,
                end_on: TimeKeeper.date_of_record.end_of_year,
                assistance_year: TimeKeeper.date_of_record.year,
                member_ids: family10.family_members.map(&:id).map(&:to_s),
                tax_household_id: tax_household.id
              )

              determination
            end

            it 'returns sum of ehb premiums of eligble members' do
              expect(@upcd_1.total_ehb_premium).to eq 1668.2
            end
          end

          context 'grants does not exists for all members' do
            let!(:eligibility_determination) do
              determination = family10.create_eligibility_determination(effective_date: TimeKeeper.date_of_record.beginning_of_year)
              determination.grants.create(
                key: "AdvancePremiumAdjustmentGrant",
                value: 1000,
                start_on: TimeKeeper.date_of_record.beginning_of_year,
                end_on: TimeKeeper.date_of_record.end_of_year,
                assistance_year: TimeKeeper.date_of_record.year,
                member_ids: [family10.primary_applicant.id.to_s],
                tax_household_id: tax_household.id
              )

              determination
            end

            it 'returns sum of ehb premiums of eligble members' do
              expect(@upcd_1.total_ehb_premium).to eq 866.07
            end
          end
        end
      end
    end

    context 'for member_ehb_premium' do
      it 'should return 0.00 when invalid information is given' do
        expect(@upcd_1.member_ehb_premium(hbx_enrollment_member1)).to eq 866.07512
      end

      it 'should return 0.00 when invalid information is given' do
        expect(@upcd_1.member_ehb_premium(hbx_enrollment_member2)).to eq 802.1383400000001
      end
    end

    context 'total_minimum_responsibility' do
      context 'feature is turned on' do
        before do
          allow(EnrollRegistry[:total_minimum_responsibility].feature).to receive(:is_enabled).and_return(true)
          @upcd_1.update_attributes(ehb: 0.999)
        end

        it 'member ehb should be one dollar less than the mem premium' do
          expect(@upcd_1.member_ehb_premium(hbx_enrollment_member2)).to eq 813.85
        end
      end

      context 'feature is turned off' do
        before do
          allow(EnrollRegistry[:total_minimum_responsibility].feature).to receive(:is_enabled).and_return(false)
          @upcd_1.update_attributes(ehb: 0.999)
        end

        it 'Should be mem premium mutliplied with ehb' do
          expect(@upcd_1.member_ehb_premium(hbx_enrollment_member2)).to eq 814.03515
        end
      end
    end
  end

  describe 'family_based_rating' do
    let(:product) do
      prod =
        FactoryBot.create(
          :benefit_markets_products_health_products_health_product,
          :with_issuer_profile,
          benefit_market_kind: :aca_individual,
          rating_method: 'Family-Tier Rates'
        )
      prod.premium_tables = [premium_table]
      prod.save
      prod
    end
    let(:premium_table)        { build(:benefit_markets_products_premium_table, rating_area: rating_area) }

    let(:family) {FactoryBot.create(:family, :with_primary_family_member_and_dependent)}
    let(:hbx_enrollment) {FactoryBot.create(:hbx_enrollment, family: family, aasm_state: 'shopping', product: product, rating_area_id: rating_area.id)}
    let!(:hbx_enrollment_member1) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, is_subscriber: true, hbx_enrollment: hbx_enrollment)}
    let!(:hbx_enrollment_member2) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[1].id, hbx_enrollment: hbx_enrollment)}
    let(:rating_area) { FactoryBot.create(:benefit_markets_locations_rating_area) }
    let(:qhp_pt) { FactoryBot.build(:products_qhp_premium_tables, couple_enrollee: 1200.00, primary_enrollee_one_dependent: 1200.00, rate_area_id: rating_area.exchange_provided_code)}
    let!(:qhp) { FactoryBot.create(:products_qhp, standard_component_id: product.hios_base_id, active_year: product.active_year, qhp_premium_tables: [qhp_pt]) }

    context 'without any aptc' do

      before do
        @decorator = UnassistedPlanCostDecorator.new(product, hbx_enrollment)
      end

      it 'should return family tier premium' do
        expect(@decorator.total_premium).to eq(1200.00)
      end
    end

    context 'with aptc' do
      let(:elected_aptc) { 500.00 }

      before do
        @decorator = UnassistedPlanCostDecorator.new(product, hbx_enrollment, elected_aptc)
      end

      it 'should return elected aptc for total aptc amount' do
        expect(@decorator.total_aptc_amount).to eq elected_aptc
      end

      it 'should return family tier premium' do
        expect(@decorator.total_premium).to eq(1200.00)
      end
    end
  end

  describe 'zero premium policy' do
    let(:product) do
      prod =
        FactoryBot.create(
          :benefit_markets_products_health_products_health_product,
          :with_issuer_profile,
          benefit_market_kind: :aca_individual,
          rating_method: 'Family-Tier Rates',
          kind: :dental
        )
      prod.premium_tables = [premium_table]
      prod.save
      prod
    end
    let(:premium_table)        { build(:benefit_markets_products_premium_table, rating_area: rating_area) }

    let(:family) {FactoryBot.create(:family, :with_primary_family_member_and_dependent)}
    let!(:person4) { FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 20.years) }
    let!(:family_member4) { FactoryBot.create(:family_member, family: family, person: person4) }
    let!(:person5) { FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 10.years) }
    let!(:family_member5) { FactoryBot.create(:family_member, family: family, person: person5) }
    let!(:person6) { FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 5.years) }
    let!(:family_member6) { FactoryBot.create(:family_member, family: family, person: person6) }
    let!(:person7) { FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 3.years) }
    let!(:family_member7) { FactoryBot.create(:family_member, family: family, person: person7) }
    let(:hbx_enrollment) {FactoryBot.create(:hbx_enrollment, family: family, aasm_state: 'shopping',coverage_kind: "dental", product: product, rating_area_id: rating_area.id)}
    let!(:hbx_enrollment_member1) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, is_subscriber: true, hbx_enrollment: hbx_enrollment)}
    let!(:hbx_enrollment_member2) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[1].id, hbx_enrollment: hbx_enrollment, is_subscriber: false)}
    let!(:hbx_enrollment_member3) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[2].id, hbx_enrollment: hbx_enrollment, is_subscriber: false)}
    let!(:hbx_enrollment_member4) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[3].id, hbx_enrollment: hbx_enrollment, is_subscriber: false)}
    let!(:hbx_enrollment_member5) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[4].id, hbx_enrollment: hbx_enrollment, is_subscriber: false)}
    let!(:hbx_enrollment_member6) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[5].id, hbx_enrollment: hbx_enrollment, is_subscriber: false)}
    let!(:hbx_enrollment_member7) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[6].id, hbx_enrollment: hbx_enrollment, is_subscriber: false)}

    let(:rating_area) { FactoryBot.create(:benefit_markets_locations_rating_area) }
    let(:qhp_pt) { FactoryBot.build(:products_qhp_premium_tables, couple_enrollee: 1200.00, primary_enrollee_one_dependent: 1200.00, rate_area_id: rating_area.exchange_provided_code)}
    let!(:qhp) { FactoryBot.create(:products_qhp, standard_component_id: product.hios_base_id, active_year: product.active_year, qhp_premium_tables: [qhp_pt]) }

    context 'when there are more then 3 dependents with age less then 21' do
      context 'when zero premium policy disabled' do
        before do
          allow(EnrollRegistry[:zero_permium_policy].feature).to receive(:is_enabled).and_return(false)
          @decorator = UnassistedPlanCostDecorator.new(product, hbx_enrollment)
        end

        it 'should return 1 for large_family_factor for 4th child dependent' do
          expect(@decorator.large_family_factor(hbx_enrollment.hbx_enrollment_members[6])).to eq(1)
        end
      end
      context 'when zero premium pollicy enabled' do
        before do
          allow(EnrollRegistry[:zero_permium_policy].feature).to receive(:is_enabled).and_return(true)
          @decorator = UnassistedPlanCostDecorator.new(product, hbx_enrollment)
        end

        it 'should return 0 for large_family_factor for 4th child dependent' do
          expect(@decorator.large_family_factor(hbx_enrollment.hbx_enrollment_members[6])).to eq(0)
        end
      end
    end
  end

  describe 'family_based_rating, with responsible party' do
    let(:product) do
      prod =
        FactoryBot.create(
          :benefit_markets_products_health_products_health_product,
          :with_issuer_profile,
          benefit_market_kind: :aca_individual,
          rating_method: 'Family-Tier Rates'
        )
      prod.premium_tables = [premium_table]
      prod.save
      prod
    end
    let(:premium_table) { build(:benefit_markets_products_premium_table, rating_area: rating_area) }

    let(:family) {FactoryBot.create(:family, :with_primary_family_member)}
    let(:spouse) do
      record = FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 20.years)
      family.primary_applicant.person.ensure_relationship_with(record, "spouse")
      record
    end
    let!(:family_member4) do
      fm = FactoryBot.create(:family_member, family: family, person: spouse)
      family.reload
      fm
    end

    let(:hbx_enrollment) {FactoryBot.create(:hbx_enrollment, family: family, aasm_state: 'shopping', product: product, rating_area_id: rating_area.id)}
    let!(:hbx_enrollment_member1) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[1].id, hbx_enrollment: hbx_enrollment)}
    let(:rating_area) { FactoryBot.create(:benefit_markets_locations_rating_area) }
    let(:qhp_pt) { FactoryBot.build(:products_qhp_premium_tables, couple_enrollee: 1200.00, primary_enrollee_one_dependent: 1200.00, rate_area_id: rating_area.exchange_provided_code)}
    let!(:qhp) { FactoryBot.create(:products_qhp, standard_component_id: product.hios_base_id, active_year: product.active_year, qhp_premium_tables: [qhp_pt]) }

    context 'without any aptc' do

      before do
        @decorator = UnassistedPlanCostDecorator.new(product, hbx_enrollment)
      end

      it 'should return family tier premium' do
        expect(@decorator.total_premium).to eq(100.00)
      end
    end
  end

  describe 'zero premium policy, with responsible party' do
    let(:product) do
      prod =
        FactoryBot.create(
          :benefit_markets_products_health_products_health_product,
          :with_issuer_profile,
          benefit_market_kind: :aca_individual,
          rating_method: 'Family-Tier Rates',
          kind: :dental
        )
      prod.premium_tables = [premium_table]
      prod.save
      prod
    end
    let(:premium_table)        { build(:benefit_markets_products_premium_table, rating_area: rating_area) }

    let(:family) {FactoryBot.create(:family, :with_primary_family_member_and_dependent)}
    let!(:person4) { FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 20.years) }
    let!(:family_member4) { FactoryBot.create(:family_member, family: family, person: person4) }
    let!(:person5) { FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 10.years) }
    let!(:family_member5) { FactoryBot.create(:family_member, family: family, person: person5) }
    let!(:person6) { FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 5.years) }
    let!(:family_member6) { FactoryBot.create(:family_member, family: family, person: person6) }
    let!(:person7) { FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 5.years) }
    let!(:family_member7) { FactoryBot.create(:family_member, family: family, person: person7) }
    let(:hbx_enrollment) {FactoryBot.create(:hbx_enrollment, family: family, aasm_state: 'shopping',coverage_kind: "dental", product: product, rating_area_id: rating_area.id)}
    let!(:hbx_enrollment_member1) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[1].id, hbx_enrollment: hbx_enrollment, is_subscriber: true)}
    let!(:hbx_enrollment_member2) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[2].id, hbx_enrollment: hbx_enrollment)}
    let!(:hbx_enrollment_member3) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[3].id, hbx_enrollment: hbx_enrollment)}
    let!(:hbx_enrollment_member4) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[4].id, hbx_enrollment: hbx_enrollment)}
    let!(:hbx_enrollment_member5) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[5].id, hbx_enrollment: hbx_enrollment)}
    let!(:hbx_enrollment_member6) {FactoryBot.create(:hbx_enrollment_member, applicant_id: family.family_members[6].id, hbx_enrollment: hbx_enrollment)}

    before(:each) do
      primary_person = family.primary_applicant.person
      spouse_person = family.family_members[1].person
      primary_person.ensure_relationship_with(spouse_person, "spouse")
      family.reload
      hbx_enrollment.reload
    end

    let(:rating_area) { FactoryBot.create(:benefit_markets_locations_rating_area) }
    let(:qhp_pt) { FactoryBot.build(:products_qhp_premium_tables, couple_enrollee: 1200.00, primary_enrollee_one_dependent: 1200.00, rate_area_id: rating_area.exchange_provided_code)}
    let!(:qhp) { FactoryBot.create(:products_qhp, standard_component_id: product.hios_base_id, active_year: product.active_year, qhp_premium_tables: [qhp_pt]) }

    context 'when there are more then 3 dependents with age less then 21' do
      context 'when zero premium policy disabled' do
        before do
          allow(EnrollRegistry[:zero_permium_policy].feature).to receive(:is_enabled).and_return(false)
          @decorator = UnassistedPlanCostDecorator.new(product, hbx_enrollment)
        end

        it 'should return 1 for large_family_factor for 4th child dependent' do
          expect(@decorator.large_family_factor(hbx_enrollment.hbx_enrollment_members[5])).to eq(1)
        end
      end
    end
  end
end
