require 'rails_helper'

describe BrokerAgency, type: :model do

  it { should validate_presence_of :name }
  it { should validate_presence_of :market_kind }
  #it { should validate_presence_of :primary_broker_id }


  let(:name) {"Acme Brokers, Inc"}
  let(:market_kind) {"individual"}
  let(:primary_broker) {FactoryGirl.create(:broker)}

  describe ".new" do
    let(:valid_params) do
      { name: name,
        market_kind: market_kind,
        primary_broker: primary_broker
      }
    end

    context "with no arguments" do
      let(:params) {{}}
       
      it "should not save" do
        expect(BrokerAgency.new(**params).save).to be_false
      end
    end
    
    context "with alll arguments" do
      let(:params) {valid_params}
       
      it "should save" do
        expect(BrokerAgency.new(**params).save!).to be_true
      end
    end

    context "with no name" do
      let(:params) {valid_params.except(:name)}

      it "should fail validation" do
        expect(BrokerAgency.create(**params).errors[:name].any?).to be_true
      end
    end

    context "with no market_kind" do
      let(:params) {valid_params.except(:market_kind)}

      it "should fail validation" do
        expect(BrokerAgency.create(**params).errors[:market_kind].any?).to be_true
      end
    end

    # context "with no primary_broker" do
    #   let(:params) {valid_params.except(:primary_broker)}
    # 
    #   it "should fail validation" do
    #     expect(BrokerAgency.create(**params).errors[:primary_broker_id].any?).to be_true
    #   end
    # end


  end

end
