require "rails_helper"

RSpec.describe VerificationHelper, :type => :helper do
  describe "#info_pop_up" do
    context "verification type SSN" do
      let(:type){"SSN"}
      let(:ssn_info){"US Passport; Social Security Card"}

      it "returns string" do
        expect(helper.info_pop_up(type)).to be_a String
      end

      it "returns the ssn supporting documents" do
        expect(helper.info_pop_up(type)).to eq ssn_info
      end
    end

    context "verification type Citizenship" do
      let(:type){"Citizenship"}
      let(:citizenship_info){'US Passport; Social Security Card; Certification of Birth Abroad (issued by the U.S. Department of State Form FS-545); Original or certified copy of a birth certificate'}

      it "returns string" do
        expect(helper.info_pop_up(type)).to be_a String
      end

      it "returns the ssn supporting documents" do
        expect(helper.info_pop_up(type)).to eq citizenship_info
      end
    end

    context "verification type Immigration status" do
      let(:type){"Immigration status"}
      let(:immigration_info){ VlpDocument::VLP_DOCUMENT_KINDS }

      it "returns string" do
        expect(helper.info_pop_up(type)).to be_a String
      end

      it "returns the list that contains 15 documents" do
        expect(helper.info_pop_up(type).split(';').count).to eq 15
      end

      it "list of the documents includes Immigration document type" do
        expect(helper.info_pop_up(type).split(';')).to include "I-327 (Reentry Permit)"
      end
    end
  end

  describe "#doc_status_label" do
    doc_status_array = VlpDocument::VLP_DOCUMENTS_VERIF_STATUS
    doc_status_classes = ["warning", "default", "success", "danger"]
    doc_status_array.each_with_index do |doc_verif_status, index|
      context "doc status is #{doc_verif_status}" do
        let(:document) { FactoryGirl.build(:vlp_document, :status=>doc_verif_status) }
        it "returns #{doc_status_classes[index]} class for #{doc_verif_status} document status" do
          expect(helper.doc_status_label(document)).to eq doc_status_classes[index]
        end
      end
    end
  end

  describe "#verification_type_status" do
    let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
    context "SSN and Citizenship type" do
      it "returns outstanding status for consumer without state residency" do
        person.consumer_role.is_state_resident = false
        assign(:person, person)
        expect(helper.verification_type_status("SSN")).to eq "outstanding"
      end

      it "returns verified status for consumer with state residency" do
        assign(:person, person)
        expect(helper.verification_type_status("SSN")).to eq "verified"
      end
    end

    context "Immigration status" do
      context "lawful presence determination successful" do
        let(:lawful_presence_determination) { FactoryGirl.build(:lawful_presence_determination) }
        it "returns verified status for consumer with state residency" do
          person.consumer_role.lawful_presence_determination = lawful_presence_determination
          assign(:person, person)
          expect(helper.verification_type_status("Immigration status")).to eq "verified"
        end
      end
      context "lawful presence determination fails" do
        let(:lawful_presence_determination) { FactoryGirl.build(:lawful_presence_determination, aasm_state: "verification_pending") }
        it "returns outstanding status for consumer without successful verification responce" do
          person.consumer_role.lawful_presence_determination = lawful_presence_determination
          assign(:person, person)
          expect(helper.verification_type_status("Immigration status")).to eq "outstanding"
        end
      end
    end

  end

  describe "#unverified?" do
    let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
    it "returns true if person is not fully verified" do
      assign(:person, person)
      expect(helper.unverified?(person)).to eq true
    end

    it "returns false if person consumer role status is fully verified" do
      person.consumer_role.aasm_state = "fully_verified"
      assign(:person, person)
      expect(helper.unverified?(person)).to be_falsey
    end
  end
end