require "rails_helper"

describe Plan do
  describe ".valid_shop_health_plans" do
    describe "by carrier" do
      let(:carrier_id) { BSON::ObjectId.new }

      let(:shop_variant_health_plan) do
        FactoryBot.build(
          :plan_template,
          :shop_health, :unoffered,
          {
            :carrier_profile_id => carrier_id,
            :active_year => 2014
          })
      end

      let(:ivl_health_plan) do
        FactoryBot.build(
          :plan_template,
          :ivl_health,
          {
            :carrier_profile_id => carrier_id,
            :active_year => 2014
          })
      end

      let(:ivl_dental_plan) do
        FactoryBot.build(
          :plan_template,
          :ivl_dental,
          {
          :active_year => 2014,
          :carrier_profile_id => carrier_id
          }
        )
      end

      let(:shop_health_plan) do
        FactoryBot.build(
          :plan_template,
          :shop_health,
          {
            :carrier_profile_id => carrier_id,
            :active_year => 2014
          })
      end

      let(:shop_dental_plan) do
        FactoryBot.build(
          :plan_template,
          :shop_dental,
          {
          :active_year => 2014,
          :carrier_profile_id => carrier_id
          }
        )
      end

      subject { Plan.valid_shop_health_plans("carrier", carrier_id, 2014) } 

      before :each do
        ivl_dental_plan.save!
        ivl_health_plan.save!
        shop_health_plan.save!
        shop_dental_plan.save!
      end

      after :each do
        shop_dental_plan.destroy!
        shop_health_plan.destroy!
        ivl_dental_plan.destroy!
        ivl_health_plan.destroy!
      end

      it "excludes -00 hios variant health plans" do
        expect(subject).not_to include(shop_variant_health_plan)
      end

      it "excludes ivl health plans" do
        expect(subject).not_to include(ivl_health_plan)
      end

      it "excludes ivl dental plans" do
        expect(subject).not_to include(ivl_dental_plan)
      end

      it "excludes shop dental plans" do
        expect(subject).not_to include(shop_dental_plan)
      end

      it "includes shop health plans" do
        expect(subject).to include(shop_health_plan)
      end
    end
  end
end
