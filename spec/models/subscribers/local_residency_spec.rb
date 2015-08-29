require "rails_helper"

describe Subscribers::LocalResidency do

  it "should subscribe to the correct event" do
    expect(Subscribers::LocalResidency.subscription_details).to eq ["acapi.info.events.residency.verification_response"]
  end

  describe "given a residency verification message to handle" do
    let(:individual_id) { "121211" }
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "residency_verification_payloads", "response.xml")) }
    let(:xml_hash) { {residency_verification_response: 'ADDRESS_NOT_IN_AREA'} }
    let(:xml_hash2) { {residency_verification_response: 'ADDRESS_IN_AREA'} }
    let(:person) { person = FactoryGirl.build(:person);
    consumer_role = person.build_consumer_role;
    consumer_role = FactoryGirl.build(:consumer_role);
    person.consumer_role = consumer_role;
    person.consumer_role.aasm_state=:verifications_pending;
    person
    }

    let(:payload) { {:individual_id => individual_id, :body => xml} }

    context "ADDRESS_NOT_IN_AREA" do
      it "should deny local residency" do
        allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash)
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(person.consumer_role.aasm_state).to eq('verifications_pending')
        expect(person.consumer_role.local_residency_responses.count).to eq(1)
        expect(person.consumer_role.local_residency_responses.first.body).to eq(payload[:body])
      end
    end

    context "ADDRESS_IN_AREA" do
      it "should approve local residency" do
        allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash2)
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(person.consumer_role.aasm_state).to eq('verifications_pending') #since lawful_presence_verified? is false
        expect(person.consumer_role.local_residency_responses.count).to eq(1)
        expect(person.consumer_role.local_residency_responses.first.body).to eq(payload[:body])
      end
    end
  end
end
