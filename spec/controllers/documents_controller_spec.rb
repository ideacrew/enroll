require 'rails_helper'

RSpec.describe DocumentsController, :type => :controller do
  let(:user) { FactoryGirl.create(:user) }
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }
  let(:consumer_role) {FactoryGirl.build(:consumer_role)}
  let(:document) {FactoryGirl.build(:vlp_document)}
  let(:family)  {FactoryGirl.create(:family, :with_primary_family_member)}
  let(:hbx_enrollment) { FactoryGirl.build(:hbx_enrollment) }
  let(:ssn_type) { FactoryGirl.build(:verification_type, type_name: 'Social Security Number') }
  let(:dc_type) { FactoryGirl.build(:verification_type, type_name: 'DC Residency') }
  let(:citizenship_type) { FactoryGirl.build(:verification_type, type_name: 'Citizenship') }
  let(:immigration_type) { FactoryGirl.build(:verification_type, type_name: 'Immigration status') }
  let(:native_type) { FactoryGirl.build(:verification_type, type_name: "American Indian Status") }

  before :each do
    sign_in user
    person.verification_types = [ssn_type, dc_type, citizenship_type, native_type, immigration_type]
  end

  describe "destroy" do
    before :each do
      person.consumer_role.vlp_documents = [document]
      delete :destroy, person_id: person.id, id: document.id
    end
    it "redirects_to verification page" do
      expect(response).to redirect_to verification_insured_families_path
    end

    it "should delete document record" do
      person.reload
      expect(person.consumer_role.vlp_documents).to be_empty
    end
  end

  describe "PUT update" do
    context "rejecting with comments" do
      before :each do
        person.consumer_role.vlp_documents = [document]
      end

      it "should redirect to verification" do
        put :update, person_id: person.id, id: document.id
        expect(response).to redirect_to verification_insured_families_path
      end

      it "updates document status" do
        put :update, person_id: person.id, id: document.id, :person=>{ :vlp_document=>{:comment=>"hghghg"}}, :comment => true, :status => "ready"
        allow(family).to receive(:update_family_document_status!).and_return(true)
        document.reload
        expect(document.status).to eq("ready")
      end

      it "updates family vlp_documents_status" do
        put :update, person_id: person.id, id: document.id
        allow(family).to receive(:update_family_document_status!).and_return(true)
      end
    end

    context "accepting without comments" do
      before :each do
        person.consumer_role.vlp_documents = [document]
      end

      it "should redirect to verification" do
        put :update, person_id: person.id, id: document.id
        expect(response).to redirect_to verification_insured_families_path
      end

      it "updates document status" do
        put :update, person_id: person.id, id: document.id, :status => "accept"
        allow(family).to receive(:update_family_document_status!).and_return(true)
        document.reload
        expect(document.status).to eq("accept")
      end
    end
  end

  describe 'POST Fed_Hub_Request' do
    before :each do
      request.env["HTTP_REFERER"] = "http://test.com"
    end
    context 'Call Hub for SSA verification' do
      it 'should redirect if verification type is SSN or Citozenship' do
        post :fed_hub_request, verification_type: ssn_type.id, person_id: person.id, id: document.id
        expect(response).to redirect_to :back
        expect(flash[:success]).to eq('Request was sent to FedHub.')
      end
    end
    context 'Call Hub for Residency verification' do
      it 'should redirect if verification type is Residency' do
        person.consumer_role.update_attributes(aasm_state: 'verification_outstanding')
        post :fed_hub_request, verification_type: dc_type.id, person_id: person.id, id: document.id
        expect(response).to redirect_to :back
        expect(flash[:success]).to eq('Request was sent to Local Residency.')
      end
    end
  end

  describe "PUT extend due date" do
    before :each do
      request.env["HTTP_REFERER"] = "http://test.com"
      put :extend_due_date, family_member_id: family.primary_applicant.id, person_id: person.id, verification_type: citizenship_type.id
    end

    it "should redirect to back" do
      expect(response).to redirect_to :back
    end
  end
  describe "PUT update_verification_type" do
    before :each do
      request.env["HTTP_REFERER"] = "http://test.com"
    end

    shared_examples_for "update verification type" do |type, reason, admin_action, attribute, result|
      it "updates #{attribute} for #{type} to #{result} with #{admin_action} admin action" do
        post :update_verification_type, { person_id: person.id,
                                          verification_type: send(type).id,
                                          verification_reason: reason,
                                          admin_action: admin_action}
        person.reload
        if attribute == "validation"
          expect(person.verification_types.find(send(type).id).validation_status).to eq(result)
        elsif attribute == "update_reason"
          expect(person.verification_types.find(send(type).id).update_reason).to eq(result)
        end
      end
    end

    context "Social Security Number verification type" do
      it_behaves_like "update verification type", "ssn_type", "E-Verified in Curam", "verify", "validation", "verified"
      it_behaves_like "update verification type", "ssn_type", "E-Verified in Curam", "verify", "update_reason", "E-Verified in Curam"
    end

    context "American Indian Status verification type" do
      before do
        person.update_attributes(:tribal_id => "444444444")
      end
      it_behaves_like "update verification type", "native_type", "Document in EnrollApp", "verify", "validation", "verified"
      it_behaves_like "update verification type", "native_type", "Document in EnrollApp", "verify", "update_reason", "Document in EnrollApp"
    end

    context "Citizenship verification type" do
      it_behaves_like "update verification type", "citizenship_type", "Document in EnrollApp", "verify", "update_reason", "Document in EnrollApp"
    end

    context "Immigration verification type" do
      it_behaves_like "update verification type", "immigration_type", "SAVE system", "verify", "update_reason", "SAVE system"
    end

    it 'updates verification type if verification reason is expired' do
      params = { person_id: person.id, verification_type: citizenship_type.id, verification_reason: 'Expired', admin_action: 'return_for_deficiency'}
      put :update_verification_type, params
      person.reload

      expect(person.verification_types.where(:type_name => citizenship_type.type_name).first.update_reason).to eq("Expired")
    end

    context "redirection" do
      it "should redirect to back" do
        post :update_verification_type, person_id: person.id
        expect(response).to redirect_to :back
      end
    end

    context "verification reason inputs" do
      it "should not update verification attributes without verification reason" do
        post :update_verification_type, { person_id: person.id,
                                          verification_type: citizenship_type.id,
                                          verification_reason: "",
                                          admin_action: "verify"}
        person.reload
        expect(person.consumer_role.lawful_presence_update_reason).to eq nil
      end

      VlpDocument::VERIFICATION_REASONS.each do |reason|
        it_behaves_like "update verification type", "citizenship_type", reason, "verify", "lawful_presence_update_reason", reason
      end
    end
  end
end
