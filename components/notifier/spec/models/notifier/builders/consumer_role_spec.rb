require 'rails_helper'

RSpec.describe 'Notifier::Builders::ConsumerRole', :dbclean => :after_each do

  describe "A new model instance" do
    let(:payload) do
      file = Rails.root.join("spec", "test_data", "notices", "proj_elig_report_aqhp_2018_test_data.csv")
      csv = CSV.open(file, "r", :headers => true)
      data = csv.to_a

      {
        "consumer_role_id" => "5c61bf485f326d4e4f00000c",
        "event_object_kind" =>  "ConsumerRole",
        "event_object_id" => "5bcdec94eab5e76691000cec",
        "notice_params" => {
          "dependents" => data.select{ |m| m["dependent"].casecmp('YES').zero? }.map(&:to_hash),
          "primary_member" => data.detect{ |m| m["dependent"].casecmp('NO').zero? }.to_hash
        }
      }
    end

    let!(:person) do
      FactoryGirl.create(:person, :with_consumer_role, hbx_id: "a16f4029916445fcab3dbc44bb7aadd0", first_name: "Samules", last_name: "Park")
    end
    let!(:family){ FactoryGirl.create(:family, :with_primary_family_member, person: person) }

    subject do
      consumer = Notifier::Builders::ConsumerRole.new
      consumer.payload = payload
      consumer.consumer_role = person.consumer_role
      consumer
    end

    context "Model attributes" do
      it "should have first name from payload" do
        expect(subject.first_name).to eq("Samules")
      end

      it "should have last name from payload" do
        expect(subject.last_name).to eq("Park")
      end

      it "should have Primary full name from payload" do
        expect(subject.primary_fullname).to eq("Samules Park")
      end

      it "should have aptc from payload" do
        expect(subject.aptc).to eq("451.88")
      end
    end

    context "Model dependent attributes" do
      it "should have dependent filer type attributes" do
        expect(subject.dependents.first['filer_type']).to eq('Filers')
        expect(subject.dependents.count).to eq(2)
      end
      it "should have dependent citizen_status attributes" do
        expect(subject.citizen_status("US")).to eq('US Citizen')
        expect(subject.dependents.count).to eq(2)
      end
    end

    context "Conditional attributes" do
      it "should have aqhp_eligible?" do
        expect(subject.aqhp_eligible?).to eq(true)
      end
    end

    context "Model Open enrollment start and end date attributes" do
      it "should have open enrollment start date" do
        expect(subject.ivl_oe_start_date). to eq('November 01, 2019')
      end

      it "should have open enrollment end date" do
        expect(subject.ivl_oe_end_date). to eq('January 31, 2020')
      end
    end


    describe 'consumer_role and address' do
      let(:consumer) {subject.consumer_role.person}
      let(:address) {consumer.mailing_address}

      context "Model address attributes" do
        it "should have address " do
          expect(address.address_1).to eq('1129 Awesome Street')
        end
      end

      context "Initializing consumer role and address mergemodels" do
        it "should have mergemodel with consumerrole and address" do
          expect(address.mailing_address.state).to eq('DC')
        end
      end
    end

  end
end
