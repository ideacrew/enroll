require 'rails_helper'

RSpec.describe DocumentsController, :type => :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let(:person_with_family) { FactoryBot.create(:person, :with_family) }
  let(:person_with_fam_hbx_enrollment) { person_with_family.primary_family.active_household.hbx_enrollments.build }
  let(:consumer_role) {FactoryBot.build(:consumer_role)}
  let(:document) {FactoryBot.build(:vlp_document)}
  let(:family)  {FactoryBot.create(:family, :with_primary_family_member)}
  let(:hbx_enrollment) { FactoryBot.build(:hbx_enrollment) }
  let(:ssn_type) { FactoryBot.build(:verification_type, type_name: 'Social Security Number') }
  let(:local_type) { FactoryBot.build(:verification_type, type_name: EnrollRegistry[:enroll_app].setting(:state_residency).item) }
  let(:citizenship_type) { FactoryBot.build(:verification_type, type_name: 'Citizenship') }
  let(:immigration_type) { FactoryBot.build(:verification_type, type_name: 'Immigration status') }
  let(:native_type) { FactoryBot.build(:verification_type, type_name: "American Indian Status") }

  before :each do
    # Needed for the American indian status type
    allow(EnrollRegistry[:indian_alaskan_tribe_details].feature).to receive(:is_enabled).and_return(false)
    sign_in user
    person.verification_types = [ssn_type, local_type, citizenship_type, native_type, immigration_type]
  end

  describe "destroy" do
    before :each do
      person.verification_types.each{|type| type.vlp_documents << document}
      delete :destroy, params: { person_id: person.id, id: document.id, verification_type: citizenship_type.id }
    end
    it "redirects_to verification page" do
      expect(response).to redirect_to verification_insured_families_path
    end

    it "should delete document record" do
      person.reload
      expect(person.verification_types.by_name("Citizenship").first.vlp_documents).to be_empty
    end

    context 'when person has outstanding verification types' do
      it 'should move consumer role to verification oustanding' do
        expect(person.consumer_role.reload.aasm_state).to eq('verification_outstanding')
      end
    end

    it "redirects if the document doesnt exist" do
      # is already destroyed in the before action
      person.reload
      delete :destroy, params: { person_id: person.id, id: document.id, verification_type: citizenship_type.id }
      expect(flash[:error]).to eq(
        l10n(
          "documents.controller.missing_document_message",
          contact_center_phone_number: EnrollRegistry[:enroll_app].settings(:contact_center_short_number).item
        )
      )
      expect(response).to redirect_to(verification_insured_families_path)
    end
  end

  describe 'GET show_docs' do
    before :each do
      allow(user).to receive(:person).and_return(person_with_family)
      person_with_fam_hbx_enrollment.family = person_with_family.primary_family
      person_with_fam_hbx_enrollment.kind = 'individual'
      person_with_fam_hbx_enrollment.save!
      user.person.stub_chain(
        'primary_family.active_household.hbx_enrollments.verification_needed'
      ).and_return([person_with_fam_hbx_enrollment])
      allow(user).to receive(:has_hbx_staff_role?).and_return(true)
    end

    it "should update enrollments to in review and redirect to verification_insured_families_path" do
      get :show_docs
      enrollment = user.person.primary_family.active_household.hbx_enrollments.verification_needed.first
      expect(enrollment.review_status).to eq('in review')
      expect(response).to redirect_to(verification_insured_families_path)
    end
  end

  describe 'POST Fed_Hub_Request' do
    let(:consumer_role) { person.consumer_role }
    let(:permission) { FactoryBot.create(:permission, :super_admin) }
    let(:user) do
      person = FactoryBot.create(:person, :with_hbx_staff_role)
      user = FactoryBot.create(:user, person: person)
      user.person.hbx_staff_role.update_attributes(permission_id: permission.id)
      user
    end
    before :each do
      request.env["HTTP_REFERER"] = "http://test.com"
      allow(consumer_role).to receive(:invoke_residency_verification!).and_return(true)
    end
    context 'Call Hub for SSA verification' do
      it 'should redirect if verification type is SSN or Citizenship' do
        post :fed_hub_request, params: { verification_type: ssn_type.id, person_id: person.id, id: document.id }
        expect(flash[:success]).to eq('Request was sent to FedHub.')
      end
    end
    context 'Call Hub for Residency verification' do
      it 'should redirect if verification type is Residency' do
        person.consumer_role.update_attributes(aasm_state: 'verification_outstanding')
        post :fed_hub_request, params: { verification_type: local_type.id, person_id: person.id, id: document.id }
        expect(flash[:success]).to eq('Request was sent to Local Residency.')
      end
    end

    context 'Call Hub for DHS verification(immigration status)' do
      before :each do
        person.verification_types = [FactoryBot.build(:verification_type, type_name: 'Immigration status')]
        person.save!
        person.consumer_role.update_attributes(aasm_state: 'verification_outstanding', active_vlp_document_id: person.consumer_role.vlp_documents.first.id)
        @immigration_type = person.verification_types.where(type_name: 'Immigration status').first
        @immigration_type.update_attributes!(inactive: false)
      end

      it 'should redirect if verification type is Immigration status' do
        post :fed_hub_request, params: { verification_type: @immigration_type.id, person_id: person.id, id: document.id }
        expect(flash[:success]).to eq('Request was sent to FedHub.')
      end

      context 'invalid vlp document type' do
        let(:bad_document) { FactoryBot.build(:vlp_document, subject: 'Other (With Alien Number)') }

        before do
          person.consumer_role.vlp_documents = [bad_document]
          person.consumer_role.active_vlp_document_id = bad_document.id
          person.save!
          @immigration_type.update_attributes!(inactive: false)
        end

        it 'should redirect if verification type is Immigration status' do
          post :fed_hub_request, params: { verification_type: @immigration_type.id, person_id: person.id, id: bad_document.id }
          expect(flash[:danger]).to eq('Please fill in your information for Document Description.')
        end
      end

      context 'no vlp document type' do
        before do
          person.consumer_role.vlp_documents = []
          person.save!
          @immigration_type.update_attributes!(inactive: false)
        end

        it 'should redirect if verification type is Immigration status' do
          post :fed_hub_request, params: { verification_type: @immigration_type.id, person_id: person.id }

          person.reload
          @immigration_type.reload
          expect(@immigration_type.validation_status).to eq 'negative_response_received'
          error_message = @immigration_type.type_history_elements.last.update_reason
          expect(error_message).to match(/Failed due to VLP Document not found/)
        end
      end
    end

    context 'when admin does not have permissions' do
      let(:permission) { FactoryBot.create(:permission, :hbx_csr_tier1) }

      it 'should redirect with pundit error' do
        post :fed_hub_request, params: { verification_type: ssn_type.id, person_id: person.id, id: document.id }
        expect(flash[:error]).to eq('Access not allowed for hbx_profile_policy.can_call_hub?, (Pundit policy)')
      end
    end
  end

  describe "PUT extend due date" do
    before :each do
      request.env["HTTP_REFERER"] = "http://test.com"
      put :extend_due_date, params: { family_member_id: family.primary_applicant.id, person_id: person.id, verification_type: citizenship_type.id }
    end

    it "should redirect to back" do
      expect(response).to redirect_to "http://test.com"
    end
  end
  describe "PUT update_verification_type" do
    before :each do
      request.env["HTTP_REFERER"] = "http://test.com"
    end

    shared_examples_for "update verification type" do |type, reason, admin_action, attribute, result|
      it "updates #{attribute} for #{type} to #{result} with #{admin_action} admin action" do
        post :update_verification_type, params:  { person_id: person.id,
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
      put :update_verification_type, params: params
      person.reload

      expect(person.verification_types.where(:type_name => citizenship_type.type_name).first.update_reason).to eq("Expired")
    end

    context "redirection" do
      it "should redirect to back" do
        post :update_verification_type, params: { person_id: person.id }
        expect(response).to redirect_to "http://test.com"
      end
    end

    context "verification reason inputs" do
      it "should not update verification attributes without verification reason" do
        post :update_verification_type, params:  { person_id: person.id,
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

    context 'admin_rejected a verification_type' do
      let!(:person) { FactoryBot.create(:person, :with_family, :with_consumer_role) }
      let!(:user) { FactoryBot.create(:user, person: person) }
      let!(:verification_type) do
        person.verification_types.create!(type_name: 'Citizenship', validation_status: 'unverified')
      end

      let(:input_params) do
        { person_id: person.id,
          verification_type: verification_type.id,
          admin_action: 'return_for_deficiency',
          family_member_id: person.primary_family.primary_applicant.id,
          verification_reason: 'Illegible' }
      end

      before do
        post :update_verification_type, params: input_params
        verification_type.reload
      end

      it "should update verification_type" do
        expect(verification_type.validation_status).to eq('rejected')
        expect(verification_type.update_reason).to eq('Illegible')
        expect(verification_type.rejected).to eq(true)
      end
    end
  end
  describe "PUT update_ridp_verification_type" do
    before :each do
      request.env["HTTP_REFERER"] = "http://test.com"
    end

    shared_examples_for "update ridp verification type" do |type, reason, admin_action, updated_attr, result|
      it "updates #{updated_attr} for #{type} to #{result} with #{admin_action} admin action" do
        post :update_ridp_verification_type, params: { person_id: person.id,
                                               ridp_verification_type: type,
                                               verification_reason: reason,
                                               admin_action: admin_action}
        person.reload
        expect(person.consumer_role.send(updated_attr)).to eq(result)
      end
    end

    context "Identity verification type" do
      it_behaves_like "update ridp verification type", "Identity", "Document in EnrollApp", "verify", "identity_validation", "valid"
      it_behaves_like "update ridp verification type", "Identity", "E-Verified in Curam", "verify", "identity_update_reason", "E-Verified in Curam"
      it_behaves_like "update ridp verification type", "Identity", "Additional Document Required", "return_for_deficiency", "identity_validation", "rejected"
    end

    context "Application verification type" do
      it_behaves_like "update ridp verification type", "Application", "Document in EnrollApp", "verify", "application_validation", "valid"
      it_behaves_like "update ridp verification type", "Application", "Document in EnrollApp", "verify", "application_update_reason", "Document in EnrollApp"
      it_behaves_like "update ridp verification type", "Application", "Additional Document Required", "return_for_deficiency", "application_validation", "rejected"
    end

    context "redirection" do
      it "should redirect to back" do
        post :update_ridp_verification_type, params: { person_id: person.id }
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "GET cartafact_download" do

    context 'not passing current user' do
      let(:tempfile) do
        tf = Tempfile.new('test.pdf')
        tf.write("DATA GOES HERE")
        tf.rewind
        tf
      end

      let(:operation_success) do
        double(
          success?: true,
          value!: tempfile
        )
      end

      before do
        allow(Operations::Documents::Download).to receive(:call).and_return(operation_success)
        get :cartafact_download, params: {model: "test", model_id: "1234", relation: "test", relation_id: "1234"}
      end

      it 'should pass' do
        expect(response.status).to eq(200)
        expect(response.headers["Content-Disposition"]).to eq 'attachment'
      end

    end
  end

  describe "authorize cartafact_download" do

    let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let!(:associated_user) {FactoryBot.create(:user, :person => person)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let!(:family_member) { family.family_members.first }
    let!(:document) {person.documents.create}

    let(:broker_agency_profile) do
      FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile)
    end

    let!(:broker_agency_staff_role) { FactoryBot.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, aasm_state: 'active')}
    let!(:broker_user) {FactoryBot.create(:user, :person => broker_agency_staff_role.person, roles: ['broker_agency_staff_role'])}
    let(:broker_agency_profile) { FactoryBot.build(:benefit_sponsors_organizations_broker_agency_profile)}

    let(:existing_broker_staff_role) do
      person.broker_agency_staff_roles.first
    end

    let(:broker_role) do
      role = BrokerRole.new(
        :broker_agency_profile => broker_agency_profile,
        :aasm_state => "applicant",
        :npn => "123456789",
        :provider_kind => "broker"
      )
      person.broker_role = role
      person.save!
      person.broker_role
    end

    before(:each) do
      family.broker_agency_accounts << BenefitSponsors::Accounts::BrokerAgencyAccount.new(benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id,
                                                                                          start_on: Time.now,
                                                                                          is_active: true)
      family.reload
    end

    it 'broker should be able to download' do
      sign_in broker_user
      get :cartafact_download, params: {model: "Person", model_id: person.id, relation: "documents", relation_id: document.id}
    end
  end
end
