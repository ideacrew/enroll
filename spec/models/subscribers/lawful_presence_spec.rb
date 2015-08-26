require "rails_helper"

describe Subscribers::LawfulPresence do

  it "should subscribe to the correct event" do
    expect(Subscribers::LawfulPresence.subscription_details).to eq ["local.enroll.lawful_presence.lawful_presence_response"]
  end

  it "should return the correct citizenship status" do
    expect(subject.send(:get_citizen_status, "citizen")).to eq("us_citizen")
    expect(subject.send(:get_citizen_status, "refugee")).to eq("alien_lawfully_present")
    expect(subject.send(:get_citizen_status, "student")).to eq("alien_lawfully_present")
    expect(subject.send(:get_citizen_status, "non_immigrant")).to eq("alien_lawfully_present")
    expect(subject.send(:get_citizen_status, "asylum_application_pending")).to eq("alien_lawfully_present")
    expect(subject.send(:get_citizen_status, "lawful_permanent_resident")).to eq("lawful_permanent_resident")
  end

  describe "given a ssa verification message to handle" do
    let(:individual_id) { "121211" }
    let(:xml) { double }
    let(:xml_hash2) {{:case_number=>"12121", :lawful_presence_indeterminate=>{:response_code=>"invalid_information", :response_text=>"Complete information."}} }
    let(:xml_hash) { {:case_number=>"12121", :lawful_presence_determination=>{:response_code=>"not_lawfully_present", :legal_status=>"lawful_permanent_resident", :employment_authorized=>"authorized", :document_results=>{:document_cert_of_naturalization=>{:case_number=>"2113123", :response_code=>"022", :response_description_text=>"Good", :tds_response_description_text=>nil, :entry_date=>nil, :admitted_to_date=>nil, :admitted_to_text=>nil, :country_birth_code=>nil, :country_citizen_code=>nil, :coa_code=>nil, :eads_expire_date=>nil, :elig_statement_code=>"011", :elig_statement_txt=>"ok", :iav_type_code=>nil, :iav_type_text=>nil, :grant_date=>nil, :grant_date_reason_code=>nil}, :document_foreign_passport=>{:case_number=>"12123123", :response_code=>"011", :response_description_text=>"Valid Passport", :tds_response_description_text=>nil, :entry_date=>nil, :admitted_to_date=>nil, :admitted_to_text=>nil, :country_birth_code=>nil, :country_citizen_code=>nil, :coa_code=>nil, :eads_expire_date=>nil, :elig_statement_code=>"01", :elig_statement_txt=>"1.1", :iav_type_code=>nil, :iav_type_text=>nil, :grant_date=>nil, :grant_date_reason_code=>nil}}}} }
    let(:person) { person = FactoryGirl.build(:person);
    consumer_role = person.build_consumer_role;
    consumer_role = FactoryGirl.build(:consumer_role);
    person.consumer_role = consumer_role;
    person.consumer_role.aasm_state=:verifications_pending;
    person
    }

    let(:payload) { {:individual_id => individual_id, :body => xml} }

    context "lawful_presence_determination" do
      it "should approve lawful presence" do
        allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash)
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(person.consumer_role.aasm_state).to eq('fully_verified')
      end
    end

    context "lawful_presence_indeterminate" do
      it "should deny lawful presence" do
        allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash2)
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(person.consumer_role.aasm_state).to eq('verifications_outstanding')
      end
    end

  end
end