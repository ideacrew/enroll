require 'rails_helper'

RSpec.describe QualifyingLifeEventKind, :type => :model do
  it { should validate_presence_of :title }
  it { should validate_presence_of :market_kind }
  it { should validate_presence_of :effective_on_kinds }
  it { should validate_presence_of :pre_event_sep_in_days }
  it { should validate_presence_of :post_event_sep_in_days }

  describe "class methods" do
    let(:valid_params)do
      {
        title: "I've married",
        market_kind: "shop",
        effective_on_kinds: ["first_of_month"],
        pre_event_sep_in_days: 0,
        post_event_sep_in_days: 30
      }
    end

    context "should return a shop event kind" do
      let(:params){ valid_params }
      let(:qlek){ QualifyingLifeEventKind.create(**params)}
      before do
        qlek.valid?
      end
      it "when params are valid" do
        expect(QualifyingLifeEventKind.shop_market_events).to include(qlek)
        expect(QualifyingLifeEventKind.shop_market_events.first).to be_instance_of QualifyingLifeEventKind
      end
    end

    context "should return a individual event kind" do
      let(:params){ valid_params.deep_merge(market_kind: "individual") }
      let(:qlek){ QualifyingLifeEventKind.create(**params)}
      before do
        qlek.valid?
      end
      it "when params are valid" do
        expect(QualifyingLifeEventKind.individual_market_events).to include(qlek)
        expect(QualifyingLifeEventKind.individual_market_events.first).to be_instance_of QualifyingLifeEventKind
      end
    end
  end

  describe "instance methods" do
    let(:esi_qlek) {FactoryGirl.create(:qualifying_life_event_kind, title: "Dependent loss of ESI due to employee gaining Medicare")}
    let(:moved_qlek) {FactoryGirl.create(:qualifying_life_event_kind, title: "I'm moving to the District of Columbia")}

    it "is_dependent_loss_of_esi?" do
      expect(esi_qlek.is_dependent_loss_of_esi?).to eq true
      expect(moved_qlek.is_dependent_loss_of_esi?).to eq false
    end

    it "is_moved_to_dc?" do
      expect(esi_qlek.is_moved_to_dc?).to eq false
      expect(moved_qlek.is_moved_to_dc?).to eq true
    end
  end
end
