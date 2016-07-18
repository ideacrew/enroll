require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "correct_citizen_with_ssn")

describe CorrectCitizenStatus do
  let(:threshold_date) { Time.mktime(2016,7,5,8,0,0) }
  let(:previous_date) { Time.mktime(2015,7,5,8,0,0) }
  let(:body_ssn_true_citizenship_true) {"<ssa_verification_result xmlns=\"http://openhbx.org/api/terms/1.0\"
              xmlns:env=\"http://schemas.xmlsoap.org/soap/envelope/\"
              xmlns:ns1=\"http://openhbx.org/api/terms/1.0\"
              xmlns:wsa=\"http://www.w3.org/2005/08/addressing\">
              <ns6:individual xmlns:bpmn=\"http://schemas.oracle.com/bpm/xpath\"
              xmlns:ns6=\"http://openhbx.org/api/terms/1.0\">
              <ns6:id><ns6:id>568e7eeb8fsdffgc</ns6:id></ns6:id>
              <ns6:person><ns6:id><ns6:id>urn:openhbx:hbx:dc0:resources:v1:person:hbx_id#xdffgg</ns6:id></ns6:id>
              <ns6:person_name><ns6:person_surname>Tysonibaison</ns6:person_surname>
              <ns6:person_given_name>Ramsey</ns6:person_given_name></ns6:person_name>
              <ns6:addresses><ns6:address><ns6:type>urn:openhbx:terms:v1:address_type#home</ns6:type>
              <ns6:address_line_1>000 Zauglom St</ns6:address_line_1>
              <ns6:location_city_name>Uryupinsk</ns6:location_city_name>
              <ns6:location_state_code>DC</ns6:location_state_code>
              <ns6:postal_code>20000</ns6:postal_code></ns6:address></ns6:addresses>
              <ns6:emails>
                <ns6:email><ns6:type>urn:openhbx:terms:v1:email_type#work</ns6:type>
                  <ns6:email_address>mail@mail.com</ns6:email_address>
                </ns6:email>
              </ns6:emails>
              <ns6:phones>
                <ns6:phone>
                  <ns6:type>urn:openhbx:terms:v1:phone_type#home</ns6:type>
                    <ns6:full_phone_number>2022022029</ns6:full_phone_number>
                  <ns6:is_preferred>false</ns6:is_preferred>
                </ns6:phone>
              </ns6:phones>
              </ns6:person>
              <ns6:person_demographics>
              <ns6:ssn>989898989</ns6:ssn>
              <ns6:sex>urn:openhbx:terms:v1:gender#female</ns6:sex>
              <ns6:birth_date>19700311</ns6:birth_date>
              <ns6:created_at>2015-10-11T02:01:03Z</ns6:created_at>
              <ns6:modified_at>2016-06-03T14:48:39Z</ns6:modified_at>
              </ns6:person_demographics></ns6:individual>
              <ns1:response_code>HS000000</ns1:response_code>
              <ns1:response_text>Success</ns1:response_text>
              <ns1:ssn_verified>true</ns1:ssn_verified>
              <ns1:citizenship_verified>true</ns1:citizenship_verified>
              <ns1:incarcerated>false</ns1:incarcerated>
              <ns1:response_text>Success</ns1:response_text>
              </ssa_verification_result>"}

  let(:body_ssn_true_citizenship_false) {
    doc = Nokogiri::XML(body_ssn_true_citizenship_true)
    doc.xpath("//ns1:citizenship_verified").first.content = "false"
    doc
  }

  let(:body_ssn_true_NO_citizenship) {
    doc = Nokogiri::XML(body_ssn_true_citizenship_true)
    doc.xpath("//ns1:citizenship_verified").remove
    doc
  }


  let(:body_ssn_false) {
    doc = Nokogiri::XML(body_ssn_true_citizenship_true)
    doc.xpath("//ns1:ssn_verified").first.content = "false"
    doc
  }

  let(:ssa_response_ssn_true_citizenship_true) { EventResponse.new({:received_at => threshold_date + 1.hour, :body => body_ssn_true_citizenship_true}) }
  let(:ssa_response_ssn_true_citizenship_false) { EventResponse.new({:received_at => threshold_date + 1.hour, :body => body_ssn_true_citizenship_false}) }
  let(:ssa_response_ssn_true_NO_citizenship) { EventResponse.new({:received_at => threshold_date + 1.hour, :body => body_ssn_true_NO_citizenship}) }
  let(:ssa_response_ssn_false) { EventResponse.new({:received_at => threshold_date + 1.hour, :body => body_ssn_false}) }
  let(:previous_response_successful) { EventResponse.new({:received_at => previous_date, :body => body_ssn_true_citizenship_true}) }
  let(:previous_response_negative) { EventResponse.new({:received_at => previous_date, :body => body_ssn_false}) }
  let(:person) { FactoryGirl.create(:person, :with_consumer_role)}


  describe "given a citizen with ssn, ssa_response after July 5" do
    subject { CorrectCitizenStatus.new("fix me task", double(:current_scope => nil)) }

    context "ssn response true" do
      before :each do
        person.consumer_role.aasm_state = "any state"
        person.consumer_role.lawful_presence_determination.aasm_state = "verification_successful"
        person.consumer_role.lawful_presence_determination.ssa_responses = []
      end
      describe "citizenship true" do
        before :each do
          person.consumer_role.lawful_presence_determination.ssa_responses << ssa_response_ssn_true_citizenship_true
          person.save!
          subject.migrate
          person.reload
        end

        it "moves person to fully_verified" do
          expect(person.consumer_role.aasm_state).to eq "fully_verified"
        end

        it "stores transition information from existing response" do
          expect(person.consumer_role.lawful_presence_determination.vlp_verified_at).to eq threshold_date
        end

        it "stores vlp authority as ssa" do
          expect(person.consumer_role.lawful_presence_determination.vlp_authority).to eq "ssa"
        end

        it "moves lawful_presence_determination to outstanding" do
          expect(person.consumer_role.lawful_presence_determination.aasm_state).to eq "verification_successful"
        end

        it "stores citizenship_result if citizenship successful" do
          expect(person.consumer_role.lawful_presence_determination.citizenship_result).to eq "us_citizen"
        end
      end

      describe "citizenship false" do
        before :each do
          person.consumer_role.lawful_presence_determination.ssa_responses << ssa_response_ssn_true_citizenship_false
          person.save!
          subject.migrate
          person.reload
        end

        it "moves person to outstanding" do
          expect(person.consumer_role.aasm_state).to eq "verification_outstanding"
        end

        it "stores transition information from existing response" do
          expect(person.consumer_role.lawful_presence_determination.vlp_verified_at).to eq threshold_date
        end

        it "stores vlp authority as ssa" do
          expect(person.consumer_role.lawful_presence_determination.vlp_authority).to eq "ssa"
        end

        it "moves lawful_presence_determination to outstanding" do
          expect(person.consumer_role.lawful_presence_determination.aasm_state).to eq "verification_outstanding"
        end
      end

      describe "no citizenship response" do
        before :each do
          person.consumer_role.lawful_presence_determination.ssa_responses << ssa_response_ssn_true_NO_citizenship
          person.save!
          subject.migrate
          person.reload
        end

        it "moves person to outstanding" do
          expect(person.consumer_role.aasm_state).to eq "verification_outstanding"
        end

        it "stores transition information from existing response" do
          expect(person.consumer_role.lawful_presence_determination.vlp_verified_at).to eq threshold_date
        end

        it "stores vlp authority as ssa" do
          expect(person.consumer_role.lawful_presence_determination.vlp_authority).to eq "ssa"
        end

        it "moves lawful_presence_determination to outstanding" do
          expect(person.consumer_role.lawful_presence_determination.aasm_state).to eq "verification_outstanding"
        end
      end
    end

    context "recent ssn response negative but previous one is successful" do
      before :each do
        person.consumer_role.aasm_state = "any state"
        person.consumer_role.lawful_presence_determination.aasm_state = "verification_successful"
        person.consumer_role.lawful_presence_determination.ssa_responses << previous_response_successful #successful
        person.consumer_role.lawful_presence_determination.ssa_responses << ssa_response_ssn_false
        person.save!
        subject.migrate
        person.reload
      end

      it "moves person to fully verified" do
        expect(person.consumer_role.aasm_state).to eq "fully_verified"
      end

      it "stores transition information from existing response" do
        expect(person.consumer_role.lawful_presence_determination.vlp_verified_at).to eq threshold_date
      end

      it "stores vlp authority as ssa" do
        expect(person.consumer_role.lawful_presence_determination.vlp_authority).to eq "ssa"
      end

      it "moves lawful_presence_determination to successful" do
        expect(person.consumer_role.lawful_presence_determination.aasm_state).to eq "verification_successful"
      end
    end

    context "recent ssn response is negative and previous one is also negative" do
      before :each do
        person.consumer_role.aasm_state = "any state"
        person.consumer_role.lawful_presence_determination.aasm_state = "verification_successful"
        person.consumer_role.lawful_presence_determination.ssa_responses << previous_response_negative #negative
        person.consumer_role.lawful_presence_determination.ssa_responses << ssa_response_ssn_false
        person.save!
        subject.migrate
        person.reload
      end

      it "moves person to fully verified" do
        expect(person.consumer_role.aasm_state).to eq "verification_outstanding"
      end

      it "stores transition information from existing response" do
        expect(person.consumer_role.lawful_presence_determination.vlp_verified_at).to eq threshold_date
      end

      it "stores vlp authority as ssa" do
        expect(person.consumer_role.lawful_presence_determination.vlp_authority).to eq "ssa"
      end

      it "moves lawful_presence_determination to successful" do
        expect(person.consumer_role.lawful_presence_determination.aasm_state).to eq "verification_outstanding"
      end
    end
  end
end
