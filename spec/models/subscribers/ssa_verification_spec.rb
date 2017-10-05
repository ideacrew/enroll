require "rails_helper"

describe Subscribers::SsaVerification do

  it "should subscribe to the correct event" do
    expect(Subscribers::SsaVerification.subscription_details).to eq ["acapi.info.events.lawful_presence.ssa_verification_response"]
  end

  describe "given a ssa verification message to handle" do
    let(:individual_id) { "121211" }
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "ssa_verification_payloads", "response.xml")) }
    let(:xml_hash) { {:response_code => "ss", :response_text => "Failed", :ssn_verification_failed => nil,
                      :death_confirmation => nil, :ssn_verified => "true", :citizenship_verified => "true",
                      :incarcerated => "false"} }
    let(:xml_hash2) { {:response_code => "ss", :response_text => "Failed", :ssn_verification_failed => "true" } }
    let(:xml_hash3) { {:response_code => "ss", :response_text => "Failed", :ssn_verification_failed => nil,
                      :death_confirmation => nil, :ssn_verified => "true", :citizenship_verified => "false",
                      :incarcerated => "false"} }
    let(:person) { FactoryGirl.create(:person, :with_consumer_role, :correlation_id => '1234')}

    let(:payload) { {:individual_id => individual_id, :correlation_id => '1234', :body => xml} }

    before :each do
      person.consumer_role.aasm_state="ssa_pending"
      person.save!
    end

    context "ssn_verified and citizenship_verified=true" do
      it "should approve lawful presence" do
        allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash)
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(person.correlation_id).to eq(payload[:correlation_id])
        expect(person.consumer_role.aasm_state).to eq('fully_verified')
        expect(person.consumer_role.lawful_presence_determination.vlp_authority).to eq('ssa')
        expect(person.consumer_role.lawful_presence_determination.citizen_status).to eq(::ConsumerRole::US_CITIZEN_STATUS)
        expect(person.consumer_role.lawful_presence_determination.ssa_responses.count).to eq(1)
        expect(person.consumer_role.lawful_presence_determination.ssa_responses.first.body).to eq(payload[:body])
      end
    end

    context "ssn_verified and citizenship_verified=false" do
      it "should approve lawful presence and set citizen_status to not_lawfully_present_in_us" do
        allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash3)
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(person.correlation_id).to eq(payload[:correlation_id])
        expect(person.consumer_role.aasm_state).to eq('verification_outstanding')
        expect(person.consumer_role.lawful_presence_determination.vlp_authority).to eq('ssa')
        #response doesn't change user's input
        expect(person.consumer_role.lawful_presence_determination.citizen_status).to eq(::ConsumerRole::US_CITIZEN_STATUS)
      end
    end

    context "ssn_verification_failed" do
      it "should deny lawful presence" do
        allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash2)
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(person.correlation_id).to eq(payload[:correlation_id])
        expect(person.consumer_role.aasm_state).to eq('verification_outstanding')
        expect(person.consumer_role.lawful_presence_determination.vlp_authority).to eq('ssa')
        expect(person.consumer_role.lawful_presence_determination.ssa_responses.count).to eq(1)
        #response doesn't change user's input
        expect(person.consumer_role.lawful_presence_determination.citizen_status).to eq(::ConsumerRole::US_CITIZEN_STATUS)
        expect(person.consumer_role.lawful_presence_determination.ssa_responses.first.body).to eq(payload[:body])
      end
    end

    context 'consumer role not update' do
      let(:person) { FactoryGirl.create(:person, :with_consumer_role, :correlation_id => '1234')}
      let(:payload) { {:individual_id => individual_id, :correlation_id => '123', :body => xml} }

      it 'should not update consumer role when person correlation id is not matched' do
        allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash2)
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)

        expect(person.correlation_id).to_not eq(payload[:correlation_id])
        expect(person.consumer_role.aasm_state).to eq('ssa_pending')
      end
    end

    context 'consumer role update' do
      let(:person) { FactoryGirl.create(:person, :with_consumer_role) }

      it 'should update consumer role when person correlation id is blank' do
        payload = {:individual_id => individual_id, :correlation_id => '123', :body => xml}
        allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash2)
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)

        expect(person.correlation_id).to_not eq(payload[:correlation_id])
        expect(person.consumer_role.aasm_state).to eq('verification_outstanding')
      end

      it 'should update consumer role when person correlation id is blank and payload correlation id is blank' do
        payload = {:individual_id => individual_id, :body => xml}
        allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash2)
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)

        expect(person.correlation_id).to eq(payload[:correlation_id])
        expect(person.consumer_role.aasm_state).to eq('verification_outstanding')
      end
    end

  end
end
