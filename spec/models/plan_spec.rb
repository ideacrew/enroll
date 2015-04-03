require 'rails_helper'

RSpec.describe Plan, type: :model do
  def carrier_profile; FactoryGirl.create(:carrier_profile); end

  def name; "BlueChoice Silver $2,000"; end
  def active_year; 2015; end
  def hios_id; "86052DC0400001-01"; end
  def carrier_profile_id; carrier_profile._id; end
  def metal_level; "platinum"; end
  def coverage_kind; "health"; end
  def market; "shop"; end
  def ehb; 0.9943; end

  def bad_active_year; (active_year + 4).to_i; end
  def bad_metal_level; "copper"; end

  def active_year_error_message; "#{bad_active_year} is an invalid active year"; end
  def metal_level_error_message; "#{bad_metal_level} is not a valid metal level kind"; end

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
      def params; {}; end
      it "should not save" do
        expect(Plan.new(**params).save).to be_false
      end
    end

    context "with all valid arguments" do
      def params; valid_params; end
      def plan; Plan.new(**params); end

      it "should save" do
        # expect(plan.inspect).to be_nil
        expect(plan.save).to be_true
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
    end

    context "with no metal_level" do
      def params; valid_params.except(:metal_level); end

      it "should fail validation " do
        expect(Plan.create(**params).errors[:metal_level].any?).to be_true
      end
    end

    context "with improper metal_level" do
      def params; valid_params.deep_merge({metal_level: bad_metal_level}); end
      it "should fail validation with improper metal_level" do
        expect(Plan.create(**params).errors[:metal_level].any?).to be_true
        expect(Plan.create(**params).errors[:metal_level]).to eq [metal_level_error_message]
      end
    end

    context "with invalid active_year" do
      def params; valid_params.deep_merge({active_year: bad_active_year}); end
      it "should fail active_year validation" do
        expect(Plan.create(**params).errors[:active_year].any?).to be_true
        expect(Plan.create(**params).errors[:active_year]).to eq [active_year_error_message]
      end
    end
  end
end

RSpec.describe Plan, type: :model do
  describe "scopes" do
    def platinum_count; 11; end
    def gold_count; 7; end
    def shop_silver_count; 5; end
    def individual_silver_count; 5; end
    def bronze_count; 3; end
    def catastrophic_count; 1; end

    let(:total_plan_count) { platinum_count + gold_count + shop_silver_count + individual_silver_count + bronze_count + catastrophic_count }

    let(:organization) { FactoryGirl.create(:organization, legal_name: "Kaiser Permanente, Inc.", dba: "Kaiser") }
    let(:carrier_profile_0) { FactoryGirl.create(:carrier_profile, abbrev: "KP", organization: organization) }
    let(:carrier_profile_1) { FactoryGirl.create(:carrier_profile) }

    let(:shop_count) { platinum_count + gold_count + shop_silver_count }
    let(:individual_count) { individual_silver_count + bronze_count + catastrophic_count }
    let(:carrier_profile_0_count) { platinum_count + gold_count + bronze_count }
    let(:carrier_profile_1_count) { shop_silver_count + individual_silver_count + catastrophic_count }

    context "with plans loaded" do
      before do
        FactoryGirl.create_list(:plan, platinum_count, metal_level: "platinum", market: "shop", carrier_profile: carrier_profile_0)
        FactoryGirl.create_list(:plan, gold_count, metal_level: "gold", market: "shop", carrier_profile: carrier_profile_0)
        FactoryGirl.create_list(:plan, shop_silver_count, metal_level: "silver", market: "shop", carrier_profile: carrier_profile_1)
        FactoryGirl.create_list(:plan, individual_silver_count, metal_level: "silver", market: "individual", carrier_profile: carrier_profile_1)
        FactoryGirl.create_list(:plan, bronze_count, metal_level: "bronze", market: "individual", carrier_profile: carrier_profile_0)
        FactoryGirl.create_list(:plan, catastrophic_count, metal_level: "catastrophic", market: "individual", carrier_profile: carrier_profile_1)
      end

      context "with no referenced scope" do
        it "should return all loaded plans" do
          expect(Plan.all.count).to eq total_plan_count
        end
      end

      context "with referenced scopes" do
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
end

RSpec.describe Plan, type: :model do
  describe "class methods" do
    describe "redis_monthly_premium" do

      it "with invalid parameters" do 
        expect(Plan.redis_monthly_premium(2014, "1234", [], 2014)).to eq []
      end

      context "with correct parameters" do
        before(:each) do
          @plan = FactoryGirl.create(:plan_with_premium_tables)
          @premium_table= @plan.premium_tables.last
          @year= @plan.active_year
          @hios_id= @plan.hios_id
          @insured_age= @plan.premium_tables.last.age
          @coverage_begin_date= "03/01/2015"
          @premium= @plan.premium_tables.last.cost

          @plan.premium_tables.create(age: @insured_age+10, cost: @premium+10, start_on: "02/20/2015", end_on: "03/09/2015")
          @plan.premium_tables.create(age: @insured_age+20, cost: @premium+20, start_on: "02/20/2015", end_on: "03/09/2015")
          @plan.save

          Plan.all.each do |plan|
            plan.premium_tables.each do |premium|
              cache_key = [plan.hios_id, plan.active_year, premium.age].join('-')
              $redis.set(cache_key, premium.cost)
            end
          end
        end

        it "should return the correct monthly premium with an age" do
          expect(Plan.redis_monthly_premium(@year, @hios_id, @insured_age, @coverage_begin_date)).to eq [{age: @insured_age, cost: @premium}]
        end

        it "should return the correct monthly premium with age array" do
          expect(Plan.redis_monthly_premium(@plan.active_year, @hios_id, [@insured_age, @insured_age+20], @coverage_begin_date)).to eq [{age: @insured_age, cost: @premium}, {age: @insured_age+20, cost: @premium + 20}]
        end

        it "should return the correct monthly premium with age array(some not store in redis)" do
          @plan.premium_tables.create(age: @insured_age+30, cost: @premium+30, start_on: "02/20/2015", end_on: "03/09/2015")
          expect(Plan.redis_monthly_premium(@plan.active_year, @hios_id, [@insured_age, @insured_age+20, @insured_age+30], @coverage_begin_date)).to eq [{age: @insured_age, cost: @premium}, {age: @insured_age+20, cost: @premium + 20}, {age: @insured_age + 30, cost: @premium + 30}]
        end
      end
    end
  end
end
