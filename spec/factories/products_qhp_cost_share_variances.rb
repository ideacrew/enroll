FactoryGirl.define do
  factory :products_qhp_cost_share_variance, :class => 'Products::QhpCostShareVariance' do

    describe "class methods" do
      let(:qhp){ double("Products::Qhp") }
      let(:plan){ double("Plan") }
      let(:qhp_cost_share_variance){ double("Products::QhpCostShareVariance") }
      context "#find_qhp" do

        before(:each) do
          allow(Products::QhpCostShareVariance).to receive(:find_qhp).and_return(qhp)
        end

        it "should return qhp object" do
        end

      end
    end

  end

end
