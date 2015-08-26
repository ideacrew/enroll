require "rails_helper"

describe Subscribers::SsaVerification do

  it "should subscribe to the correct event" do
    expect(Subscribers::SsaVerification.subscription_details).to eq ["local.enroll.lawful_presence.ssa_verification_response"]
  end

  describe "given a ssa verification message to handle" do
    let(:individual_id) { "121211" }
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "ssa_verification_payloads", "response.xml")) }
    let(:xml_hash) { {:response_code => "ss", :response_text => "Failed", :ssn_verification_failed => nil,
                      :death_confirmation => nil, :ssn_verified => "true", :citizenship_verified => "true",
                      :incarcerated => "false", :individual => {:person => {:id => "45552", :first_name => "Kim", :last_name => "Camp", :name_pfx => "", :name_sfx => "", :middle_name => "L", :full_name => "adas", :addresses => [{:address_1 => "0000 Columbia Rd NW APT 0", :address_2 => "", :city => "Washington", :state => "DC", :country => nil, :location_state_code => "DC", :zip => "20000", :kind => "home"}], :emails => [{:email_address => "abcd@gmail.com", :kind => "home"}], :phones => [{:area_code => "001", :country_code => nil, :extension => nil, :phone_number => "3126000000", :kind => "home"}]}, :person_demographics => {:ssn => "101010101", :sex => "urn:openhbx:terms:v1:gender#male", :birth_date => "19800130", :is_state_resident => "true", :citizen_status => "urn:openhbx:terms:v1:citizen_status#us_citizen", :marital_status => nil, :death_date => nil, :race => nil, :ethnicity => nil, :is_incarcerated => nil}, :id => "45552"}} }
    let(:xml_hash2) { {:response_code => "ss", :response_text => "Failed", :ssn_verification_failed => "true", :individual => {:person => {:id => "45552", :first_name => "Kim", :last_name => "Camp", :name_pfx => "", :name_sfx => "", :middle_name => "L", :full_name => "adas", :addresses => [{:address_1 => "0000 Columbia Rd NW APT 0", :address_2 => "", :city => "Washington", :state => "DC", :country => nil, :location_state_code => "DC", :zip => "20000", :kind => "home"}], :emails => [{:email_address => "abcd@gmail.com", :kind => "home"}], :phones => [{:area_code => "001", :country_code => nil, :extension => nil, :phone_number => "3126000000", :kind => "home"}]}, :person_demographics => {:ssn => "101010101", :sex => "urn:openhbx:terms:v1:gender#male", :birth_date => "19800130", :is_state_resident => "true", :citizen_status => "urn:openhbx:terms:v1:citizen_status#us_citizen", :marital_status => nil, :death_date => nil, :race => nil, :ethnicity => nil, :is_incarcerated => nil}, :id => "45552"}} }

    let(:person) { person = FactoryGirl.build(:person);
    consumer_role = person.build_consumer_role;
    consumer_role = FactoryGirl.build(:consumer_role);
    person.consumer_role = consumer_role;
    person.consumer_role.aasm_state=:verifications_pending;
    person
    }

    let(:payload) { {:individual_id => individual_id, :body => xml} }

    context "ssn_verified" do
      it "should approve lawful presence" do
        allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash)
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(person.consumer_role.aasm_state).to eq('fully_verified')
      end
    end

    context "ssn_verification_failed" do
      it "should deny lawful presence" do
        allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash2)
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(person.consumer_role.aasm_state).to eq('verifications_outstanding')
      end
    end

  end
end
