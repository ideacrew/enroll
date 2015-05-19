require 'rails_helper'

RSpec.describe QualifyingLifeEventKind, :type => :model do
  it { should validate_presence_of :title }
  it { should validate_presence_of :market_kind }
  it { should validate_presence_of :effective_on_kind }
  it { should validate_presence_of :pre_event_sep_in_days }
  it { should validate_presence_of :post_event_sep_in_days }

  describe "class methods" do
    let(:valid_params)do
      {
        title: "I've married",
        market_kind: "shop",
        effective_on_kind: "first_of_month",
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

end