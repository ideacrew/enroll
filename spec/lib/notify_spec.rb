require 'rails_helper'

describe Notify do
  before do 
    extend Notify
  end

  context "notify_change_envent function" do
    let(:person){FactoryGirl.build(:person)}
    let(:per){FactoryGirl.create(:person)}
    before(:all) do
      @instance = Object.new
      @instance.extend(Notify) 
    end

    it "fire right notify function" do
      expect(@instance).to receive(:notify).with("acapi.info.events.enrollment.person_created", person.to_xml)
      @instance.notify_change_event(person, {"identifying_info"=>["first_name"]}, {})
    end

    it "fire right notify function when change record" do
      first_name = per.first_name
      per.first_name = "test"
      expect(@instance).to receive(:notify).with("acapi.info.events.enrollment.person_changed", [{"identifying_info"=>[{"first_name"=>[first_name, "test"]}]}].to_xml)
      @instance.notify_change_event(per, {"identifying_info"=>["first_name"]}, {})
    end
  end

  context "paypload function" do
    let(:person){FactoryGirl.create(:person)}

    it "will call notify with change person's first_name" do
      first_name = person.first_name
      person.first_name = "Test"
      expect(payload(person, attributes: {"identifying_info"=>["first_name"]}, relationshop_attributes: {})).to eq [{"identifying_info"=>[{"first_name"=>[first_name, "Test"]}]}]
    end

    it "will call notify with change person email" do
      email = person.emails.last.address
      person.emails.last.address = "test@home.com"
      expect(payload(person, attributes: {"identifying_info"=>["first_name"]}, relationshop_attributes: {"address_change"=>["emails"]})).to eq [{"address_change"=>[{"emails"=>[{"address"=>[email, "test@home.com"]}]}]}]
    end
  end

end
