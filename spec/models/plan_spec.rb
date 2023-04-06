require 'rails_helper'

RSpec.describe Plan, dbclean: :after_each do
  def carrier_profile;
    FactoryBot.create(:carrier_profile);
  end

  def name;
    "BlueChoice Silver $2,000";
  end

  def active_year;
    TimeKeeper.date_of_record.year;
  end

  def hios_id;
    "86052DC0400001-01";
  end

  def carrier_profile_id;
    carrier_profile._id;
  end

  def metal_level;
    "platinum";
  end

  def coverage_kind;
    "health";
  end

  def market;
    "shop";
  end

  def ehb;
    0.9943;
  end

  def bad_active_year;
    (active_year + 4).to_i;
  end

  def bad_metal_level;
    "copper";
  end

  def active_year_error_message;
    "#{bad_active_year} is an invalid active year";
  end

  def metal_level_error_message;
    "#{bad_metal_level} is not a valid metal level kind";
  end

  it { should validate_presence_of :name }
  it { should validate_presence_of :carrier_profile_id }
  it { should validate_presence_of :hios_id }
  it { should validate_presence_of :active_year }

  describe ".new" do
    let(:valid_params) do
      {
          name: name,
          active_year: active_year,
          hios_id: hios_id,
          carrier_profile_id: carrier_profile_id,
          metal_level: metal_level,
          coverage_kind: coverage_kind,
          market: market
      }
    end

    context "with no arguments" do
      def params;
        {};
      end

      it "should not save" do
        expect(Plan.new(**params).save).to be_falsey
      end
    end

    context "with all valid arguments" do
      def params;
        valid_params;
      end

      def plan;
        Plan.new(**params);
      end

      it "should save" do
        # expect(plan.inspect).to be_nil
        expect(plan.save).to be_truthy
      end

      context "and it is saved" do
        let!(:saved_plan) do
          alt_plan = plan
          alt_plan.hios_id = "86052DC0400001-02"
          alt_plan.save
          alt_plan
        end

        it "should be findable" do
          expect(Plan.find(saved_plan.id).id.to_s).to eq saved_plan.id.to_s
        end
      end

      context "check associations with plan model with renewal plan mapping" do
        it "embeds_many assiciation check" do
          association = Plan.reflect_on_association(:renewal_plan_mappings)
          expect(association.class).to eq (Mongoid::Association::Embedded::EmbedsMany)
          expect(association.name).to eq (:renewal_plan_mappings)
        end
      end
    end

    context "check plan offerings scope" do
      let!(:sole_source_plan) { create(:plan, is_sole_source: true, is_horizontal: false, is_vertical: false) }
      let!(:horizontal_plan) { create(:plan, is_horizontal: true, is_sole_source: false, is_vertical: false) }
      let!(:vertical_plan) { create(:plan, is_vertical: true, is_sole_source: false, is_horizontal: false) }
      let!(:regular_plan) { create(:plan) } # we are creating this because when it is creating it will assign :is_sole_source, :is_horizontal, :is_vertical with default true boolean value


      it "should return only sole source plans" do
        expect(Plan.check_plan_offerings_for_sole_source).to contain_exactly(sole_source_plan, regular_plan)
      end

      it "should return only horizantal plans" do
        expect(Plan.check_plan_offerings_for_metal_level).to contain_exactly(horizontal_plan, regular_plan)
      end

      it "should return only vertical plans" do
        expect(Plan.check_plan_offerings_for_single_carrier).to contain_exactly(vertical_plan, regular_plan)
      end

      it "should check for field for filtering available or not" do
        is_expected.to have_attributes(:frozen_plan_year => nil)
      end

    end

    context "renewal_plan_mapping filter by date" do
      let(:calender_year) { TimeKeeper.date_of_record.year }
      let!(:sole_source_plan) { create(:plan, is_sole_source: true, renewal_plan_id: renewal_health_plan.id, active_year: calender_year) }
      let!(:renewal_health_plan) { create(:plan, coverage_kind: "health", active_year: calender_year + 1) }
      let!(:neighbour_plan) { create(:plan, is_sole_source: true, active_year: calender_year + 1) }
      let(:current_date) { Date.new(calender_year, 4, 10) }

      before do
        TimeKeeper.set_date_of_record_unprotected!(current_date)
      end

      after :each do
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
      end

      context "when carrier mappings not present" do
        it "should return same carrier renewal plan" do
          expect(sole_source_plan.renewal_plan).to eq renewal_health_plan
        end
      end

      context "when carrier mapping present" do
        let(:renewal_plan_status) { true }

        let!(:renewal_plan_mappings1) {
          sole_source_plan.renewal_plan_mappings.create({
            start_on: Date.new(calender_year, 1, 1),
            end_on: Date.new(calender_year, 5, 1).end_of_month,
            renewal_plan_id: neighbour_plan.id,
            is_active: renewal_plan_status
          })
        }

        context "is not active" do
          let(:renewal_plan_status) { false }

          it "should return just regular renewal plan" do
            expect(sole_source_plan.renewal_plan(current_date)).to eq renewal_health_plan
          end
        end

        context "is active" do
          it "should return renewal plan from mapping" do
            expect(sole_source_plan.renewal_plan(current_date)).to eq neighbour_plan
          end
        end

        context "is expired" do
          let(:current_date) { Date.new(calender_year, 6, 10) }

          it "should return just regular renewal plan" do
            expect(sole_source_plan.renewal_plan(current_date)).to eq renewal_health_plan
          end
        end
      end
    end

    context "with no metal_level" do
      def params;
        valid_params.except(:metal_level);
      end

      it "should fail validation " do
        expect(Plan.create(**params).errors[:metal_level].any?).to be_truthy
      end
    end

    context "with improper metal_level" do
      def params;
        valid_params.deep_merge({metal_level: bad_metal_level});
      end

      it "should fail validation with improper metal_level" do
        expect(Plan.create(**params).errors[:metal_level].any?).to be_truthy
        expect(Plan.create(**params).errors[:metal_level]).to eq [metal_level_error_message]
      end
    end

    context "with invalid active_year" do
      def params;
        valid_params.deep_merge({active_year: bad_active_year});
      end

      it "should fail active_year validation" do
        expect(Plan.create(**params).errors[:active_year].any?).to be_truthy
        expect(Plan.create(**params).errors[:active_year]).to eq [active_year_error_message]
      end
    end

    context "with empty dental metal level for coverage_kind = health" do

      def params;
        valid_params.deep_merge({dental_level: "", coverage_kind: "health"});
      end

      it "should not save plan object" do
        expect(Plan.create(**params).errors[:dental_level].any?).to be_falsey
      end
    end

    context "with empty dental metal level for coverage_kind = dental" do

      def params;
        valid_params.deep_merge({dental_level: "", coverage_kind: "dental"});
      end

      it "should not save plan object" do
        expect(Plan.create(**params).errors[:dental_level].any?).to be_truthy
        expect(Plan.create(**params).errors[:dental_level]).to eq [" is not a valid dental metal level kind"]
      end
    end

    context "with invalid dental metal level for coverage_kind = dental" do

      def params;
        valid_params.deep_merge({dental_level: "invalid", coverage_kind: "dental"});
      end

      it "should not save plan object" do
        expect(Plan.create(**params).errors[:dental_level].any?).to be_truthy
        expect(Plan.create(**params).errors[:dental_level]).to eq ["invalid is not a valid dental metal level kind"]
      end
    end

    context "with valid dental metal level for coverage_kind = dental" do

      def params;
        valid_params.deep_merge({dental_level: "low", coverage_kind: "dental"});
      end

      it "should not save plan object" do
        expect(Plan.create(**params).errors[:dental_level].any?).to be_falsey
      end
    end
  end

  describe "dental_level" do
    context "check valid options for dental level metal level kind" do
      it "should return true if valid options are present" do
        expect(Plan::DENTAL_METAL_LEVEL_KINDS).to eq ["high", "low"]
      end

      it "should return false if invalid options are present" do
        expect(Plan::DENTAL_METAL_LEVEL_KINDS).not_to eq ["dental", "high", "low"]
      end
    end
  end


  describe ".premium_table_for" do
    let(:valid_plan_params) do
      {
          name: name,
          active_year: active_year,
          hios_id: hios_id,
          carrier_profile_id: carrier_profile_id,
          metal_level: metal_level,
          coverage_kind: coverage_kind,
          market: market,
          premium_tables: [ premium_table_entry1,
                            premium_table_entry2,
                            premium_table_entry3,
                            premium_table_entry4 ]
      }
    end

    let(:premium_table_entry1) { {
      start_on: "2015-01-01",
      end_on: "2015-05-31",
      cost: 500,
      age: 32
      } }

    let(:premium_table_entry2) { {
      start_on: "2015-06-01",
      end_on: "2015-08-31",
      cost: 502,
      age: 32
      } }

    let(:premium_table_entry3) { {
      start_on: "2015-09-01",
      end_on: "2015-12-31",
      cost: 504,
      age: 32
      } }

    let(:premium_table_entry4) { {
      start_on: "2015-09-01",
      end_on: "2015-12-31",
      cost: 574,
      age: 34
      } }


    context "valid arguments" do

      def plan;
        Plan.new(valid_plan_params);
      end

      def premium_table_hash(premium_table)
        {
          start_on: premium_table.start_on.try(:strftime, "%Y-%m-%d"),
          end_on: premium_table.end_on.try(:strftime, "%Y-%m-%d"),
          cost: premium_table.cost,
          age: premium_table.age
        }
      end

      it "should return premium tables" do
        expect(plan.premium_table_for(Date.parse("2015-10-01")).size).to eq 2
        expect(premium_table_hash(plan.premium_table_for(Date.parse("2015-10-01"))[0])).to eq premium_table_entry3
        expect(premium_table_hash(plan.premium_table_for(Date.parse("2015-10-01"))[1])).to eq premium_table_entry4
      end
    end
  end

  describe ".premium_for" do
    let(:valid_plan_params) do
      {
          name: name,
          active_year: active_year,
          hios_id: hios_id,
          carrier_profile_id: carrier_profile_id,
          metal_level: metal_level,
          coverage_kind: coverage_kind,
          market: market,
          premium_tables: [{start_on: "2015-01-01",
                            end_on: "2015-12-31",
                            cost: 500,
                            age: 32}]
      }
    end

    context "invalid arguments" do
      def plan_params;
        valid_plan_params;
      end

      def plan;
        Plan.new(**plan_params);
      end

      it "should raise exception" do
        expect { plan.premium_for(Date.today.at_beginning_of_month, params[:premium_tables][0][:age] + 1) }.to raise_error(NameError)
      end
    end

    context "valid arguments" do

      def plan_params;
        valid_plan_params;
      end

      def plan;
        Plan.new(**plan_params);
      end

      it "should compute premium" do
        expect(plan.premium_for(Date.parse("2015-10-01"), plan_params[:premium_tables][0][:age])).to eq(plan_params[:premium_tables][0][:cost])
      end

      it "should round premium amount" do
        allow(BigDecimal).to receive_message_chain(:new, :round, :to_f).and_return("45.45")
        expect(plan.premium_for(Date.parse("2015-10-01"), plan_params[:premium_tables][0][:age])).to eq "45.45"
      end
    end
  end

  describe ".ehb" do
    let(:plan1) {FactoryBot.create(:plan, ehb: 0.9)}
    let(:plan2) {FactoryBot.create(:plan, ehb: 1)}

    it "should get ehb from db when ehb more than 0" do
      expect(plan1.ehb).to eq 0.9
    end

    it "should return 1 when ehb equal 0" do
      expect(plan2.ehb).to eq 1
    end
  end
end

RSpec.describe Plan, dbclean: :after_each do
  describe "scopes" do
    def platinum_count;
      11;
    end

    def gold_count;
      7;
    end

    def shop_silver_count;
      5;
    end

    def individual_silver_count;
      5;
    end

    def bronze_count;
      3;
    end

    def catastrophic_count;
      1;
    end

    let(:in_service_area_count) { platinum_count + individual_silver_count }

    let(:total_plan_count) { platinum_count + gold_count + shop_silver_count + individual_silver_count + bronze_count + catastrophic_count }

    let(:organization) { FactoryBot.create(:organization, legal_name: "Kaiser Permanente, Inc.", dba: "Kaiser Permanente") }
    let(:carrier_profile_0) { FactoryBot.create(:carrier_profile, abbrev: "KP", organization: organization, issuer_hios_ids: ['11111']) }
    let(:carrier_profile_1) { FactoryBot.create(:carrier_profile) }
    let(:carrier_service_area) { create(:carrier_service_area, issuer_hios_id: '11111', serves_entire_state: true, service_area_id: 'EX123') }
    let(:shop_count) { platinum_count + gold_count + shop_silver_count }
    let(:individual_count) { individual_silver_count + bronze_count + catastrophic_count }
    let(:carrier_profile_0_count) { platinum_count + gold_count + bronze_count }
    let(:carrier_profile_0_without_bronze_count) { platinum_count + gold_count }
    let(:carrier_profile_1_count) { shop_silver_count + individual_silver_count + catastrophic_count }
    let(:current_year) {TimeKeeper.date_of_record.year}
    let(:next_year) {current_year + 1}

    context "with plans loaded" do
      before do
        FactoryBot.create_list(:plan, platinum_count, metal_level: "platinum", market: "shop", plan_type: "ppo", carrier_profile: carrier_profile_0, active_year: current_year-1, service_area_id: 'EX123')
        FactoryBot.create_list(:plan, gold_count, metal_level: "gold", market: "shop", plan_type: "pos", carrier_profile: carrier_profile_0, active_year: current_year, service_area_id: 'EX111')
        FactoryBot.create_list(:plan, shop_silver_count, metal_level: "silver", plan_type: "ppo", market: "shop", carrier_profile: carrier_profile_1, active_year: current_year, service_area_id: 'EX222')
        FactoryBot.create_list(:plan, individual_silver_count, metal_level: "silver", market: "individual", plan_type: "hmo", carrier_profile: carrier_profile_1, active_year: current_year, service_area_id: 'EX123')
        FactoryBot.create_list(:plan, bronze_count, metal_level: "bronze", market: "individual", plan_type: "epo", carrier_profile: carrier_profile_0, active_year: current_year, service_area_id: 'EX321')
        FactoryBot.create_list(:plan, catastrophic_count, metal_level: "catastrophic", market: "individual", plan_type: "hmo", carrier_profile: carrier_profile_1, active_year: current_year, service_area_id: 'EX321')
      end

      context "with no referenced scope" do
        it "should return all loaded plans" do
          expect(Plan.all.count).to eq total_plan_count
        end
      end

      context "by_active_year" do
        it "should return all plans of this year" do
          expect(Plan.by_active_year.count).to eq (total_plan_count - platinum_count)
        end
      end

      context "for_service_areas" do
        it 'should return all plans assigned the given service area ids' do
          expect(Plan.for_service_areas(['EX123']).count).to eq(in_service_area_count)
        end
      end

      context "valid_shop_by_carrier" do
        it "should return all carrier_profile_1 plans this year" do
          expect(Plan.valid_shop_by_carrier(carrier_profile_1.id).count).to eq shop_silver_count
        end
      end

      context "valid_shop_by_metal_level" do
        it "should return all silver plans this year" do
          expect(Plan.valid_shop_by_metal_level('silver').count).to eq shop_silver_count
        end
      end

      context "valid_shop_by_carrier_and_year" do
        it "should return all carrier_profile_1 plans this year" do
          expect(Plan.valid_shop_by_carrier_and_year(carrier_profile_1.id, current_year).count).to eq shop_silver_count
        end

        it "should return no carrier_profile_1 plans next year" do
          expect(Plan.valid_shop_by_carrier_and_year(carrier_profile_1.id, next_year).count).to eq 0
        end
      end

      context "valid_shop_by_metal_level_and_year" do
        it "should return all silver plans this year" do
          expect(Plan.valid_shop_by_metal_level_and_year('silver', current_year).count).to eq shop_silver_count
        end

        it "should return no silver plans next year" do
          expect(Plan.valid_shop_by_metal_level_and_year('silver', next_year).count).to eq 0
        end
      end

      context "individual health by active year" do
        it "should return individual count" do
          expect(Plan.individual_health_by_active_year(current_year).size).to eq individual_silver_count + bronze_count + catastrophic_count
        end

        it "should not return plan which hios_id not ends with -01" do
          plan = Plan.where(market: "individual").first
          plan.update(hios_id: "1212312312322-02")

          expect(Plan.individual_health_by_active_year(current_year).size).to eq individual_silver_count + bronze_count + catastrophic_count - 1
        end
      end

      context "with referenced plan_type scope of either ppo, hmo, pos, epo" do
        it "should return all loaded plans" do
          expect(Plan.ppo_plan.size).to eq shop_silver_count + platinum_count
          expect(Plan.pos_plan.size).to eq gold_count
          expect(Plan.hmo_plan.size).to eq individual_silver_count + catastrophic_count
          expect(Plan.epo_plan.size).to eq bronze_count
        end
      end

      context "with referenced scopes" do
        let(:enabled_metal_levels) { %w(platinum gold silver bronze) }

        before do
          allow(Plan).to receive(:enabled_metal_levels).and_return(enabled_metal_levels)
        end
        it "should return correct counts for each metal scope" do
          expect(Plan.platinum_level.count).to eq platinum_count
          expect(Plan.gold_level.count).to eq gold_count
          expect(Plan.silver_level.count).to eq shop_silver_count + individual_silver_count
          expect(Plan.bronze_level.count).to eq bronze_count
          expect(Plan.catastrophic_level.count).to eq catastrophic_count
        end

        it "should return correct counts for each market scope" do
          expect(Plan.shop_market.count).to eq shop_count
          expect(Plan.individual_market.count).to eq individual_count
        end

        it "should return correct counts for each carrier_profile scope" do
          expect(Plan.find_by_carrier_profile(carrier_profile_0).count).to eq carrier_profile_0_count
          expect(Plan.find_by_carrier_profile(carrier_profile_1).count).to eq carrier_profile_1_count
        end

        context "should return correct counts for carriers if metal levels are restricted" do
          let(:enabled_metal_levels) { %w(platinum gold silver) }

          it "returns a count less bronze plans" do
            expect(Plan.find_by_carrier_profile(carrier_profile_0).with_enabled_metal_levels.count).to eq carrier_profile_0_without_bronze_count
          end
        end

        it "should return correct counts for chained scopes" do
          expect(Plan.shop_market.silver_level.count).to eq shop_silver_count
          expect(Plan.individual_market.silver_level.count).to eq individual_silver_count

          expect(Plan.find_by_carrier_profile(carrier_profile_0).gold_level.count).to eq gold_count
          expect(Plan.find_by_carrier_profile(carrier_profile_1).silver_level.count).to eq shop_silver_count + individual_silver_count
          expect(Plan.find_by_carrier_profile(carrier_profile_0).shop_market.count).to eq platinum_count + gold_count
        end
      end
    end
  end

  describe "class method" do
    it "reference_plan_metal_level_for_options" do
      expect(Plan.reference_plan_metal_level_for_options).to eq Plan::REFERENCE_PLAN_METAL_LEVELS.map{|k| [k.humanize, k]}
    end

    context "valid_shop_health_plans" do
      let(:carrier_profile) {FactoryBot.create(:carrier_profile)}
      before :each do
        Rails.cache.clear
      end

      it "for carrier" do
        expect(Plan.valid_shop_health_plans('carrier', carrier_profile.id)).to eq Plan.valid_shop_by_carrier(carrier_profile.id).to_a
      end

      it "for metal_level" do
        expect(Plan.valid_shop_health_plans('metal_level', 'gold')).to eq Plan.valid_shop_by_metal_level('gold').to_a
      end
    end

    context "individual_plans" do
      let(:plan1) { FactoryBot.create(:plan, :with_premium_tables, market: 'individual', metal_level: 'gold', active_year: TimeKeeper.date_of_record.year, hios_id: "11111111122302-01", csr_variant_id: "01") }
      let(:plan2) { FactoryBot.create(:plan, :with_premium_tables, market: 'individual', metal_level: 'silver', active_year: TimeKeeper.date_of_record.year, hios_id: "11111111122303", csr_variant_id: "06") }
      let(:plan3) { FactoryBot.create(:plan, :with_premium_tables, market: 'individual', metal_level: 'gold', active_year: TimeKeeper.date_of_record.year, hios_id: "11111111122304-01", csr_variant_id: "01") }
      let(:plan4) { FactoryBot.create(:plan, :with_premium_tables, market: 'individual', coverage_kind: 'dental', dental_level: "high", active_year: TimeKeeper.date_of_record.year, hios_id: "11111111122305-02") }
      let!(:family) { create(:family, :with_primary_family_member_and_dependent) }
      let!(:person) { family.primary_person }
      let(:household) {create(:household, family: family)}
      let!(:tax_household) {create(:tax_household, household: household)}
      let!(:tax_household_member) {tax_household.tax_household_members.create!(is_ia_eligible: true, csr_eligibility_kind: "csr_94")}

      let(:hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, is_subscriber: true, applicant_id: person.primary_family.family_members[0].id) }
      let(:hbx_enrollment) do
        FactoryBot.create(:hbx_enrollment, :with_product,
                          family: family,
                          household: household,
                          hbx_enrollment_members: [hbx_enrollment_member],
                          coverage_kind: "health")
      end

      before :each do
        Plan.delete_all
        tax_household.tax_household_members.first.update_attributes!(applicant_id: family.family_members.first.id)
      end

      it "should return dental plans" do
        plans = [plan4]
        expect(Plan.individual_plans(coverage_kind:'dental', active_year:TimeKeeper.date_of_record.year, tax_household:nil,  hbx_enrollment: hbx_enrollment).to_a).to eq plans
      end

      it "should return health plans without silver" do
        plans = [plan1, plan3]
        expect(Plan.individual_plans(coverage_kind:'health', active_year:TimeKeeper.date_of_record.year, tax_household:nil,  hbx_enrollment: hbx_enrollment).to_a).to include(plan1,plan3)
      end

      it "should return health plans" do
        tax_household.tax_household_members.update_all(csr_eligibility_kind: "csr_94")
        plans = [plan2]
        expect(Plan.individual_plans(coverage_kind: 'health', active_year: TimeKeeper.date_of_record.year, tax_household: tax_household, hbx_enrollment: hbx_enrollment).to_a).to eq plans
      end
    end
  end

  describe "Instance method" do
    it "catastrophic plan can not use aptc" do
      plan = FactoryBot.create(:plan, metal_level: 'catastrophic')
      expect(plan.can_use_aptc?).to eq false
    end

    it "normal metal_level plan can use aptc" do
      plan = FactoryBot.build(:plan)
      (Plan::METAL_LEVEL_KINDS - ['catastrophic']).each do |metal_level|
        plan.metal_level = metal_level
        expect(plan.can_use_aptc?).to eq true
      end
    end
  end
end
