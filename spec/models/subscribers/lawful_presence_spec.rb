require "rails_helper"

describe Subscribers::LawfulPresence do

  it "should subscribe to the correct event" do
    expect(Subscribers::LawfulPresence.subscription_details).to eq ["acapi.info.events.lawful_presence.vlp_verification_response"]
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
    let(:xml) { File.read(Rails.root.join("spec", "test_data", "lawful_presence_payloads", "response.xml")) }
    let(:xml2) { File.read(Rails.root.join("spec", "test_data", "lawful_presence_payloads", "response2.xml")) }
    let(:xml_hash) { {:case_number => "12121", :is_barred => true, :bar_met => "true",:lawful_presence_determination => {
        :response_code => "lawfully_present", :is_barred => true, :bar_met => "true", :legal_status => "lawful_permanent_resident"}} }
    let(:xml_hash2) { {:case_number => "12121", :is_barred => true, :bar_met => "true", :lawful_presence_indeterminate => {:response_code => "invalid_information",
                                                                                   :response_text => "Complete information."}} }
    let(:xml_hash3) { {:case_number => "12121", :lawful_presence_determination => {
        :response_code => "not_lawfully_present", :legal_status => "other"}} }
    let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
    let(:consumer_role) { person.consumer_role }
    let(:verif_type) { person.verification_types.active.where(type_name:"Immigration status").first }
    let(:history_elements) { verif_type.type_history_elements }

    before do
      consumer_role.aasm_state = "dhs_pending"
      consumer_role.citizen_status = "alien_lawfully_present"
      person.us_citizen = false
      person.save
    end
    let(:response_data) { Parsers::Xml::Cv::LawfulPresenceResponseParser.parse(xml) }

    context "stores DHS response in verification history" do
      let(:payload) { {:individual_id => individual_id, :body => xml} }
      it "stores verification history element" do
        history_elements.delete_all
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(history_elements.count).to be > 0
      end

      it "stores verification history element with correct information" do
        history_elements.delete_all
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(history_elements.first.action).to eq "DHS Hub response"
      end

      it "stores reference to EventResponse in verification history element" do
        history_elements.delete_all
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(BSON::ObjectId.from_string(history_elements.first.event_response_record_id)).to eq consumer_role.lawful_presence_determination.vlp_responses.first.id
      end
    end

    context "lawful_presence_determination" do
      let(:payload) { {:individual_id => individual_id, :body => xml} }
      context "lawfully_present" do
        it "should approve lawful presence" do
          allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash)
          allow(subject).to receive(:find_person).with(individual_id).and_return(person)
          subject.call(nil, nil, nil, nil, payload)
          expect(person.consumer_role.aasm_state).to eq('fully_verified')
          expect(person.consumer_role.is_barred).to be true
          expect(person.consumer_role.bar_met).to be true
          expect(person.consumer_role.lawful_presence_determination.vlp_authority).to eq('dhs')
          expect(Person.find(person.id).consumer_role.lawful_presence_determination.vlp_responses.count).to eq(1)
          expect(Person.find(person.id).consumer_role.lawful_presence_determination.vlp_responses.first.body).to eq(payload[:body])
        end
      end

      context "dhs response for lawful precence indeterminent" do
        it "should save dhs response" do
          allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash)
          allow(subject).to receive(:find_person).with(individual_id).and_return(person)
  
          subject.call(nil, nil, nil, nil, payload)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.length).to eq(1)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.case_number).to eq(response_data.case_number)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.response_code).to eq(response_data.lawful_presence_indeterminate.response_code)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.response_text).to eq(response_data.lawful_presence_indeterminate.response_text)
        end
      end

      context 'dhs response for lawful presence determinate' do
        let(:payload) { {:individual_id => individual_id, :body => xml2} }
        let(:xml2) { File.read(Rails.root.join("spec", "test_data", "lawful_presence_payloads", "response2.xml")) }
        let(:response_data) { Parsers::Xml::Cv::LawfulPresenceResponseParser.parse(xml2) }
        
        it 'should save dhs response' do
          
          allow(subject).to receive(:xml_to_hash).with(xml2).and_return(xml_hash)
          allow(subject).to receive(:find_person).with(individual_id).and_return(person)
          subject.call(nil, nil, nil, nil, payload)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.length).to eq(1)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.case_number).to eq(response_data.case_number)

          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.document_DS2019).to eq(response_data.lawful_presence_determination.document_results.document_DS2019)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.document_I20).to eq(response_data.lawful_presence_determination.document_results.document_I20)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.document_I327).to eq(response_data.lawful_presence_determination.document_results.document_I327)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.document_I551).to eq(response_data.lawful_presence_determination.document_results.document_I551)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.document_I571).to eq(response_data.lawful_presence_determination.document_results.document_I571)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.document_I766).to eq(response_data.lawful_presence_determination.document_results.document_I766)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.document_I94).to eq(response_data.lawful_presence_determination.document_results.document_I94)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.document_cert_of_citizenship).to eq(response_data.lawful_presence_determination.document_results.document_cert_of_citizenship)
      
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.cert_of_naturalization_admitted_to_date).to eq(response_data.lawful_presence_determination.document_results.document_cert_of_naturalization.admitted_to_date)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.cert_of_naturalization_admitted_to_text).to eq(response_data.lawful_presence_determination.document_results.document_cert_of_naturalization.admitted_to_text)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.cert_of_naturalization_case_number).to eq(response_data.lawful_presence_determination.document_results.document_cert_of_naturalization.case_number)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.cert_of_naturalization_coa_code).to eq(response_data.lawful_presence_determination.document_results.document_cert_of_naturalization.coa_code)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.cert_of_naturalization_country_birth_code).to eq(response_data.lawful_presence_determination.document_results.document_cert_of_naturalization.country_birth_code)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.cert_of_naturalization_country_citizen_code).to eq(response_data.lawful_presence_determination.document_results.document_cert_of_naturalization.country_citizen_code)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.cert_of_naturalization_eads_expire_date).to eq(response_data.lawful_presence_determination.document_results.document_cert_of_naturalization.eads_expire_date)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.cert_of_naturalization_elig_statement_code).to eq(response_data.lawful_presence_determination.document_results.document_cert_of_naturalization.elig_statement_code)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.cert_of_naturalization_elig_statement_txt).to eq(response_data.lawful_presence_determination.document_results.document_cert_of_naturalization.elig_statement_txt)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.cert_of_naturalization_entry_date).to eq(response_data.lawful_presence_determination.document_results.document_cert_of_naturalization.entry_date)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.cert_of_naturalization_grant_date).to eq(response_data.lawful_presence_determination.document_results.document_cert_of_naturalization.grant_date)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.cert_of_naturalization_grant_date_reason_code).to eq(response_data.lawful_presence_determination.document_results.document_cert_of_naturalization.grant_date_reason_code)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.cert_of_naturalization_iav_type_code).to eq(response_data.lawful_presence_determination.document_results.document_cert_of_naturalization.iav_type_code)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.cert_of_naturalization_iav_type_text).to eq(response_data.lawful_presence_determination.document_results.document_cert_of_naturalization.iav_type_text)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.cert_of_naturalization_response_code).to eq(response_data.lawful_presence_determination.document_results.document_cert_of_naturalization.response_code)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.cert_of_naturalization_response_description_text).to eq(response_data.lawful_presence_determination.document_results.document_cert_of_naturalization.response_description_text)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.cert_of_naturalization_tds_response_description_text).to eq(response_data.lawful_presence_determination.document_results.document_cert_of_naturalization.tds_response_description_text)

          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.passport_admitted_to_date).to eq(response_data.lawful_presence_determination.document_results.document_foreign_passport.admitted_to_date)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.passport_admitted_to_text).to eq(response_data.lawful_presence_determination.document_results.document_foreign_passport.admitted_to_text)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.passport_case_number).to eq(response_data.lawful_presence_determination.document_results.document_foreign_passport.case_number)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.passport_coa_code).to eq(response_data.lawful_presence_determination.document_results.document_foreign_passport.coa_code)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.passport_country_birth_code).to eq(response_data.lawful_presence_determination.document_results.document_foreign_passport.country_birth_code)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.passport_country_citizen_code).to eq(response_data.lawful_presence_determination.document_results.document_foreign_passport.country_citizen_code)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.passport_eads_expire_date).to eq(response_data.lawful_presence_determination.document_results.document_foreign_passport.eads_expire_date)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.passport_elig_statement_code).to eq(response_data.lawful_presence_determination.document_results.document_foreign_passport.elig_statement_code)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.passport_elig_statement_txt).to eq(response_data.lawful_presence_determination.document_results.document_foreign_passport.elig_statement_txt)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.passport_entry_date).to eq(response_data.lawful_presence_determination.document_results.document_foreign_passport.entry_date)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.passport_grant_date).to eq(response_data.lawful_presence_determination.document_results.document_foreign_passport.grant_date)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.passport_grant_date_reason_code).to eq(response_data.lawful_presence_determination.document_results.document_foreign_passport.grant_date_reason_code)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.passport_iav_type_code).to eq(response_data.lawful_presence_determination.document_results.document_foreign_passport.iav_type_code)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.passport_iav_type_text).to eq(response_data.lawful_presence_determination.document_results.document_foreign_passport.iav_type_text)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.passport_response_code).to eq(response_data.lawful_presence_determination.document_results.document_foreign_passport.response_code)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.passport_response_description_text).to eq(response_data.lawful_presence_determination.document_results.document_foreign_passport.response_description_text)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.passport_tds_response_description_text).to eq(response_data.lawful_presence_determination.document_results.document_foreign_passport.tds_response_description_text)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.document_foreign_passport_I94).to eq(response_data.lawful_presence_determination.document_results.document_foreign_passport_I94)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.document_mac_read_I551).to eq(response_data.lawful_presence_determination.document_results.document_mac_read_I551)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.document_other_case_1).to eq(response_data.lawful_presence_determination.document_results.document_other_case_1)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.document_other_case_2).to eq(response_data.lawful_presence_determination.document_results.document_other_case_2)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.document_temp_I551).to eq(response_data.lawful_presence_determination.document_results.document_temp_I551)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.legal_status).to eq(response_data.lawful_presence_determination.legal_status)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.employment_authorized).to eq(response_data.lawful_presence_determination.employment_authorized)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.response_code).to eq(response_data.lawful_presence_determination.response_code)
          expect(person.consumer_role.lawful_presence_determination.dhs_verification_responses.last.lawful_presence_indeterminate).to eq(response_data.lawful_presence_indeterminate)
        end
      end

      context "unlawfully_present" do
        it "should approve lawful presence" do
          allow(subject).to receive(:xml_to_hash).with(xml).and_return(xml_hash3)
          allow(subject).to receive(:find_person).with(individual_id).and_return(person)
          subject.call(nil, nil, nil, nil, payload)
          expect(person.consumer_role.aasm_state).to eq('verification_outstanding')
          expect(person.consumer_role.lawful_presence_determination.vlp_authority).to eq('dhs')
          expect(Person.find(person.id).consumer_role.lawful_presence_determination.vlp_responses.count).to eq(1)
          expect(Person.find(person.id).consumer_role.lawful_presence_determination.vlp_responses.first.body).to eq(payload[:body])
        end
      end
    end

    context "lawful_presence_indeterminate" do
      let(:payload) { {:individual_id => individual_id, :body => xml2} }
      it "should deny lawful presence" do
        allow(subject).to receive(:xml_to_hash).with(xml2).and_return(xml_hash2)
        allow(subject).to receive(:find_person).with(individual_id).and_return(person)
        subject.call(nil, nil, nil, nil, payload)
        expect(person.consumer_role.aasm_state).to eq('verification_outstanding')
        expect(person.consumer_role.lawful_presence_determination.vlp_authority).to eq('dhs')
        expect(Person.find(person.id).consumer_role.lawful_presence_determination.vlp_responses.count).to eq(1)
        expect(Person.find(person.id).consumer_role.lawful_presence_determination.vlp_responses.first.body).to eq(payload[:body])
      end
    end

  end
end
