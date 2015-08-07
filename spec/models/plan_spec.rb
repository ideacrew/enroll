require 'rails_helper'

RSpec.describe Plan, dbclean: :after_each do
  def carrier_profile;
    FactoryGirl.create(:carrier_profile);
  end

  def name;
    "BlueChoice Silver $2,000";
  end

  def active_year;
    2015;
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
        expect { plan.premium_for(Date.today.at_beginning_of_month, params[:premium_tables][0][:age] + 1) }.to raise_error
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
        FactoryGirl.create_list(:plan, platinum_count, metal_level: "platinum", market: "shop", plan_type: "ppo", carrier_profile: carrier_profile_0)
        FactoryGirl.create_list(:plan, gold_count, metal_level: "gold", market: "shop", plan_type: "pos", carrier_profile: carrier_profile_0)
        FactoryGirl.create_list(:plan, shop_silver_count, metal_level: "silver", plan_type: "ppo", market: "shop", carrier_profile: carrier_profile_1)
        FactoryGirl.create_list(:plan, individual_silver_count, metal_level: "silver", market: "individual", plan_type: "hmo", carrier_profile: carrier_profile_1)
        FactoryGirl.create_list(:plan, bronze_count, metal_level: "bronze", market: "individual", plan_type: "epo", carrier_profile: carrier_profile_0)
        FactoryGirl.create_list(:plan, catastrophic_count, metal_level: "catastrophic", market: "individual", plan_type: "hmo", carrier_profile: carrier_profile_1)
      end

      context "with no referenced scope" do
        it "should return all loaded plans" do
          expect(Plan.all.count).to eq total_plan_count
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
