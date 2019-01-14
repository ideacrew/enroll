require 'rails_helper'

describe Notify do
  before do 
    extend Notify
  end

  context "notify_change_envent function" do
    let(:person){FactoryBot.build(:person)}
    let(:per){FactoryBot.create(:person)}
    before(:all) do
      @instance = Object.new
      @instance.extend(Notify) 
    end

    it "fire right notify function when create" do
      #expect(@instance).to receive(:notify).exactly(1).times
      expect(@instance).to receive(:notify).with("acapi.info.events.enrollment.person_identifying_info_first_name", {"status" => "created", "first_name" => [nil, person.first_name]}.to_xml)
      @instance.notify_change_event(person, {"identifying_info"=>["first_name"]})
    end

    it "fire right notify function when change record" do
      first_name = per.first_name
      per.first_name = "test"
      expect(@instance).to receive(:notify).with("acapi.info.events.enrollment.person_identifying_info_first_name", {"status"=>"changed", "first_name"=>[first_name, "test"]}.to_xml)
      @instance.notify_change_event(per, {"identifying_info"=>["first_name"]})
    end
  end

  context "paypload function" do
    let(:person){FactoryBot.create(:person)}
    let(:per){FactoryBot.build(:person)}

    context "for field" do
      it "will call notify with change person's first_name" do
        first_name = person.first_name
        person.first_name = "Test"
        expect([payload(person, field: "first_name")]).to eq [{"status" => "changed", "first_name" => [first_name, "Test"]}]
      end

      it "will call notify with create person" do
        expect([payload(per, field: "first_name")]).to eq [{"status" => "created", "first_name" => [nil, per.first_name]}]
      end
    end

    context "for embeds_many relationship" do
      it "will call notify with change person emails" do
        email = person.emails.last.address
        person.emails.last.address = "test@home.com"
        expect([payload(person, field: "emails")]).to eq [{"status"=>"changed", "emails"=>[{"address"=>[email, "test@home.com"]}]}]
      end

      it "will call notify with create person emails" do
        email = person.emails.new(kind: :home, address: "test@home.com")
        expect([payload(person, field: "emails")]).to eq [{"status"=>"created", "emails"=>[email]}]
      end
    end

    context "for embeds_one relationship" do
      let(:broker_role) {FactoryBot.build(:broker_role)}
      let(:br) {FactoryBot.create(:broker_role)}

      it "will call notify with create person broker_role" do
        expect([payload(broker_role.person, field: "broker_role")]).to eq [{"status"=>"created", "broker_role"=>broker_role}]
      end

      it "will call notify with change person broker_role" do
        npn = br.npn
        br.npn = "test123"
        expect([payload(br.person, field: "broker_role")]).to eq [{"status"=>"changed", "broker_role"=>{"npn"=>[npn, "test123"]}}]
      end
    end
  end
end
