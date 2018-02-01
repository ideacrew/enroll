require 'rails_helper'

class FakesController < ApplicationController
  include VlpDoc
end

describe FakesController do
  let(:consumer_role) { FactoryGirl.create(:person, :with_consumer_role).consumer_role }
  let(:params) { { consumer_role: { vlp_documents_attributes: { "0" => { expiration_date: "06/23/2016" }}}, naturalized_citizen: false, eligible_immigration_status: false } }
  let(:person_params) { ActionController::Parameters.new({person: params }) }
  let(:dependent_params) { ActionController::Parameters.new({dependent: params }) }

  context "documents updating" do
    shared_examples_for "updating consumer documents" do |params|
      let(:person_kind) { params.split("_").first.to_sym }
      before :each do
        subject.instance_variable_set("@params", eval(params))
        allow(subject).to receive(:params).and_return(eval(params))
      end

      it "should convert the date string to dateTime instance" do
        expect(subject.params[person_kind]).to be_a(Hash)
        expect(subject.params[person_kind][:consumer_role]).to be_a(Hash)
        expect(subject.params[person_kind][:consumer_role][:vlp_documents_attributes]["0"]).to be_a(Hash)
        expect(subject.params[person_kind][:consumer_role][:vlp_documents_attributes]["0"][:expiration_date]).to be_a(String)
        expect(subject.update_vlp_documents(consumer_role, person_kind))
        expect(subject.params[person_kind][:consumer_role][:vlp_documents_attributes]["0"][:expiration_date]).to be_a(DateTime)
      end
    end

    it_behaves_like "updating consumer documents", "person_params"
    it_behaves_like "updating consumer documents", "dependent_params"
  end

  context "#get_vlp_doc_subject_by_consumer_role" do
    let(:vlp_doc_naturalized) { FactoryGirl.build(:vlp_document, :subject => "Certificate of Citizenship" ) }
    let(:vlp_doc_immigrant) { FactoryGirl.build(:vlp_document, :subject => "I-327 (Reentry Permit)" ) }
    shared_examples_for "returns vlp document subject" do |doc_subject, citizen_status|
      before do
        consumer_role.vlp_documents = [vlp_doc_naturalized, vlp_doc_immigrant]
      end
      describe "#{citizen_status}" do
        before do
          consumer_role.vlp_documents << FactoryGirl.build(:vlp_document, :subject => doc_subject)
          consumer_role.citizen_status = citizen_status
        end
        it "returns nil if no consumer role" do
          expect(subject.get_vlp_doc_subject_by_consumer_role(nil)).to be_nil
        end
        it "returns #{doc_subject}" do
          expect(subject.get_vlp_doc_subject_by_consumer_role(consumer_role)).to be doc_subject
        end
      end
    end

    naturalized_citizen_docs = ["Certificate of Citizenship", "Naturalization Certificate"]

    naturalized_citizen_docs.each do |document|
      it_behaves_like "returns vlp document subject", document, "naturalized_citizen"
    end

    VlpDocument::VLP_DOCUMENT_KINDS.each do |document|
      it_behaves_like "returns vlp document subject", document, "eligible_immigration_status"
    end

    context "consumer role having invalid vlp document" do
      let(:invalid_document) { FactoryGirl.build(:vlp_document, subject: "I-551 (Permanent Resident Card)", alien_number: "243")}

      before do
        consumer_role.vlp_documents = [invalid_document]
      end

      it "should not return subject" do
        expect(subject.get_vlp_doc_subject_by_consumer_role(consumer_role)).to be_nil
      end
    end
  end

  context "#sensitive_info_changed?" do

    let(:person_params) { { person:  { no_dc_address: "true" } } }

    let(:person) { FactoryGirl.create(:person, :with_consumer_role, :no_dc_address => false)}

    before do
      allow(subject).to receive(:params).and_return person_params
    end

    it "should return true for info_changed if sensitive_information changed" do
      allow(person.consumer_role).to receive(:sensitive_information_changed?).with(person_params[:person]).and_return true
      expect(subject.sensitive_info_changed?(person.consumer_role)[0]).to eq true
    end

    it "should return false for info_changed if sensitive_information not changed" do
      allow(person.consumer_role).to receive(:sensitive_information_changed?).with(person_params[:person]).and_return false
      expect(subject.sensitive_info_changed?(person.consumer_role)[0]).to eq false
    end

    it "should return false as dc_status if the past addreess is in dc" do
      expect(subject.sensitive_info_changed?(person.consumer_role)[1]).to eq false
    end

    it "should return true as dc_status if the past addreess is in non-dc" do
      person.update_attributes(no_dc_address: true)
      expect(subject.sensitive_info_changed?(person.consumer_role)[1]).to eq true
    end
  end
end
