# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe DocumentsController, dbclean: :after_each, :type => :controller do
  #super admin hbx staff role
  let(:admin_person) { FactoryBot.create(:person, :with_hbx_staff_role) }
  let(:admin_user) {FactoryBot.create(:user, :with_hbx_staff_role, :person => admin_person)}
  let!(:permission) { FactoryBot.create(:permission, :super_admin) }
  let!(:update_admin) { admin_person.hbx_staff_role.update_attributes(permission_id: permission.id) }

  #associated consumer role
  let(:consumer_person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:consumer_user) { FactoryBot.create(:user, person: consumer_person) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: consumer_person) }
  let!(:dependent_person) do
    person = family.family_members.where(is_primary_applicant: false).first.person
    FactoryBot.create(:consumer_role,  person: person, dob: person.dob)
    person
  end
  let!(:consumer_role) do
    consumer_person.consumer_role.update_attributes(aasm_state: 'verification_outstanding')
    consumer_person.consumer_role
  end
  let(:document) {FactoryBot.build(:vlp_document)}
  let(:ssn_type) { FactoryBot.build(:verification_type, type_name: 'Social Security Number') }
  let(:local_type) { FactoryBot.build(:verification_type, type_name: EnrollRegistry[:enroll_app].setting(:state_residency).item) }
  let(:citizenship_type) { FactoryBot.build(:verification_type, type_name: 'Citizenship') }
  let(:immigration_type) { FactoryBot.build(:verification_type, type_name: 'Immigration status') }
  let(:immigration_type_for_dependent) { dependent_person.verification_types.create!(type_name: 'Citizenship', validation_status: 'unverified') }
  let(:native_type) { FactoryBot.build(:verification_type, type_name: "American Indian Status") }

  # unauthorized consumer role
  let(:fake_person) { FactoryBot.create(:person, :with_consumer_role) }
  let(:fake_user) { FactoryBot.create(:user, person: fake_person) }
  let!(:fake_family) { FactoryBot.create(:family, :with_primary_family_member, person: fake_person) }
  let!(:fake_consumer_role) do
    fake_person.consumer_role.update_attributes(aasm_state: 'verification_outstanding')
    fake_person.consumer_role
  end

  # broker role
  let(:broker_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile, market_kind: :individual) }
  let(:broker_role) { FactoryBot.create(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, aasm_state: :active) }
  let!(:broker_role_user) {FactoryBot.create(:user, :person => broker_role.person, roles: ['broker_role'])}

  # broker staff role
  let(:broker_agency_staff_role) { FactoryBot.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, aasm_state: 'active')}
  let!(:broker_agency_staff_user) {FactoryBot.create(:user, :person => broker_agency_staff_role.person, roles: ['broker_agency_staff_role'])}

  before :each do
    # Needed for the American indian status type
    allow(EnrollRegistry[:indian_alaskan_tribe_details].feature).to receive(:is_enabled).and_return(false)
    consumer_role.move_identity_documents_to_verified
  end

  describe "destroy" do
    before :each do
      consumer_person.verification_types = [ssn_type, local_type, citizenship_type, native_type, immigration_type]
      consumer_person.verification_types.each{|type| type.vlp_documents << document}
      sign_in consumer_user
      delete :destroy, params: { person_id: consumer_person.id, id: document.id, verification_type: citizenship_type.id }
    end

    it "redirects_to verification page" do
      expect(response).to redirect_to verification_insured_families_path
    end

    it "should delete document record" do
      consumer_person.reload
      expect(consumer_person.verification_types.by_name("Citizenship").first.vlp_documents).to be_empty
    end

    context 'when person has outstanding verification types' do
      it 'should move consumer role to verification oustanding' do
        expect(consumer_role.reload.aasm_state).to eq('verification_outstanding')
      end
    end

    it "redirects if the document doesnt exist" do
      consumer_person.reload
      delete :destroy, params: { person_id: consumer_person.id, id: document.id, verification_type: citizenship_type.id }
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
    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01') }
    let(:hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: TimeKeeper.date_of_record.beginning_of_month) }

    before :each do
      consumer_role.person.verification_types = [ssn_type, local_type, citizenship_type, native_type, immigration_type]
      consumer_person.verification_types.update_all(validation_status: "outstanding")
      FactoryBot.create(:hbx_enrollment,
                        product: product,
                        hbx_enrollment_members: [hbx_enrollment_member],
                        family: family,
                        is_any_enrollment_member_outstanding: true,
                        household: family.active_household,
                        coverage_kind: "health",
                        effective_on: TimeKeeper.date_of_record.next_month.beginning_of_month,
                        enrollment_kind: "open_enrollment",
                        kind: "individual",
                        submitted_at: TimeKeeper.date_of_record,
                        aasm_state: 'coverage_selected')

      sign_in admin_user
    end

    it "should update enrollments to in review and redirect to verification_insured_families_path" do
      get :show_docs,  params: {person_id: consumer_person.id}
      enrollment = family.active_household.hbx_enrollments.verification_needed.first
      expect(enrollment.review_status).to eq('in review')
      expect(response).to redirect_to(verification_insured_families_path)
    end
  end

  describe 'POST Fed_Hub_Request' do
    before :each do
      request.env["HTTP_REFERER"] = "http://test.com"
      allow(consumer_role).to receive(:invoke_residency_verification!).and_return(true)
      consumer_person.verification_types = [ssn_type, local_type, citizenship_type, native_type, immigration_type]
      dependent_person.verification_types = [immigration_type_for_dependent]
      sign_in admin_user
    end

    context 'Call Hub for SSA verification' do
      it 'should redirect if verification type is SSN or Citizenship' do
        post :fed_hub_request, params: { verification_type: ssn_type.id, person_id: consumer_person.id, id: document.id }
        expect(flash[:success]).to eq('Request was sent to FedHub.')
      end
    end

    context 'Call Hub for Residency verification' do
      it 'should redirect if verification type is Residency' do
        consumer_person.consumer_role.update_attributes(aasm_state: 'verification_outstanding')
        post :fed_hub_request, params: { verification_type: local_type.id, person_id: consumer_person.id, id: document.id }
        expect(flash[:success]).to eq('Request was sent to Local Residency.')
      end
    end

    context 'Call Hub for DHS verification(immigration status)' do
      before :each do
        consumer_person.verification_types = [FactoryBot.build(:verification_type, type_name: 'Immigration status')]
        consumer_person.save!
        consumer_person.consumer_role.update_attributes(aasm_state: 'verification_outstanding', active_vlp_document_id: consumer_person.consumer_role.vlp_documents.first.id)
        @immigration_type = consumer_person.verification_types.where(type_name: 'Immigration status').first
        @immigration_type.update_attributes!(inactive: false)
      end

      it 'should redirect if verification type is Immigration status' do
        post :fed_hub_request, params: { verification_type: @immigration_type.id, person_id: consumer_person.id, id: document.id }
        expect(flash[:success]).to eq('Request was sent to FedHub.')
      end

      context 'invalid vlp document type' do
        let(:bad_document) { FactoryBot.build(:vlp_document, subject: 'Other (With Alien Number)') }

        before do
          consumer_person.consumer_role.vlp_documents = [bad_document]
          consumer_person.consumer_role.active_vlp_document_id = bad_document.id
          consumer_person.save!
          @immigration_type.update_attributes!(inactive: false)
        end

        it 'should redirect if verification type is Immigration status' do
          post :fed_hub_request, params: { verification_type: @immigration_type.id, person_id: consumer_person.id, id: bad_document.id }
          expect(flash[:danger]).to eq('Please fill in your information for Document Description.')
        end
      end

      context 'no vlp document type' do
        before do
          consumer_person.consumer_role.vlp_documents = []
          consumer_person.save!
          @immigration_type.update_attributes!(inactive: false)
        end

        it 'should redirect if verification type is Immigration status' do
          post :fed_hub_request, params: { verification_type: @immigration_type.id, person_id: consumer_person.id }

          consumer_person.reload
          @immigration_type.reload
          expect(@immigration_type.validation_status).to eq 'negative_response_received'
          error_message = @immigration_type.type_history_elements.last.update_reason
          expect(error_message).to match(/Failed due to VLP Document not found/)
        end
      end
    end

    context 'enrolled' do
      let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01') }
      let(:hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: TimeKeeper.date_of_record.beginning_of_month) }
      let(:hbx_enrollment) do
        FactoryBot.create(:hbx_enrollment,
                          hbx_enrollment_members: [hbx_enrollment_member],
                          family: family,
                          product: product,
                          is_any_enrollment_member_outstanding: true,
                          household: family.active_household,
                          coverage_kind: "health",
                          effective_on: TimeKeeper.date_of_record.next_month.beginning_of_year,
                          enrollment_kind: "open_enrollment",
                          kind: "individual",
                          submitted_at: TimeKeeper.date_of_record,
                          aasm_state: 'coverage_selected')
      end

      before do
        hbx_enrollment
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:set_due_date_upon_response_from_hub).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_ssn).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:location_residency_verification_type).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:indian_alaskan_tribe_details).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:include_faa_outstanding_verifications).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:crm_update_family_save).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:check_for_crm_updates).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_quadrant).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:display_county).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:notify_address_changed).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:financial_assistance).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:alive_status).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:crm_publish_primary_subscriber).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:async_publish_updated_families).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:ssa_h3).and_return(true)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_errors).and_return(true)
        consumer_person.verification_types = [FactoryBot.build(:verification_type, type_name: 'Immigration status')]
        consumer_person.consumer_role.vlp_documents = []
        consumer_person.save!
        @immigration_type = consumer_person.verification_types.where(type_name: 'Immigration status').first
        @immigration_type.pending_type
        @immigration_type.update_attributes!(inactive: false)
        [
          :financial_assistance,
          :'gid://enroll_app/Family',
          :aptc_csr_credit,
          :aca_individual_market_eligibility,
          :health_product_enrollment_status,
          :dental_product_enrollment_status
        ].each do |feature_key|
          EnrollRegistry[feature_key].feature.stub(:is_enabled).and_return(true)
        end
      end

      it 'change due date on family level' do
        post :fed_hub_request, params: { verification_type: @immigration_type.id, person_id: consumer_person.id }
        consumer_person.reload
        @immigration_type.reload
        family.reload
        family_due_date = family.eligibility_determination&.outstanding_verification_earliest_due_date
        expect(family_due_date).to match(@immigration_type.due_date)
      end

      it 'change due date on family level for non-primary family member' do
        immigration_type_for_dependent.pending_type
        post :fed_hub_request, params: { verification_type: immigration_type_for_dependent.id, person_id: dependent_person.id }
        dependent_person.reload
        immigration_type_for_dependent.reload
        family.reload
        family_due_date = family.eligibility_determination&.outstanding_verification_earliest_due_date
        expect(family_due_date).to match(@immigration_type.due_date)
      end
    end

    context 'when admin does not have permissions' do
      let(:permission) { FactoryBot.create(:permission, :hbx_csr_tier1) }

      it 'should redirect with pundit error' do
        post :fed_hub_request, params: { verification_type: ssn_type.id, person_id: consumer_person.id, id: document.id }
        expect(flash[:error]).to eq('Access not allowed for hbx_profile_policy.can_call_hub?, (Pundit policy)')
      end
    end
  end

  describe "PUT extend due date" do
    before :each do
      request.env["HTTP_REFERER"] = "http://test.com"
      consumer_role.person.verification_types = [ssn_type, local_type, citizenship_type, native_type, immigration_type]
      sign_in admin_user
      put :extend_due_date, params: { family_member_id: family.primary_applicant.id, person_id: consumer_person.id, verification_type: citizenship_type.id }
    end

    it "should redirect to back" do
      expect(response).to redirect_to "http://test.com"
    end
  end

  describe "PUT update_verification_type" do
    before :each do
      request.env["HTTP_REFERER"] = "http://test.com"
      consumer_role.person.verification_types = [ssn_type, local_type, citizenship_type, native_type, immigration_type]
      sign_in admin_user
    end

    shared_examples_for "update verification type" do |type, reason, admin_action, attribute, result|
      it "updates #{attribute} for #{type} to #{result} with #{admin_action} admin action" do
        post :update_verification_type, params: { person_id: consumer_person.id,
                                                  verification_type: send(type).id,
                                                  verification_reason: reason,
                                                  admin_action: admin_action}
        consumer_person.reload
        case attribute
        when "validation"
          expect(consumer_person.verification_types.find(send(type).id).validation_status).to eq(result)
        when "update_reason"
          expect(consumer_person.verification_types.find(send(type).id).update_reason).to eq(result)
        end
      end
    end

    context "Social Security Number verification type" do
      it_behaves_like "update verification type", "ssn_type", "E-Verified in Curam", "verify", "validation", "verified"
      it_behaves_like "update verification type", "ssn_type", "E-Verified in Curam", "verify", "update_reason", "E-Verified in Curam"
    end

    context "American Indian Status verification type" do
      before do
        consumer_person.update_attributes(:tribal_id => "444444444")
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
      params = { person_id: consumer_person.id, verification_type: citizenship_type.id, verification_reason: 'Expired', admin_action: 'return_for_deficiency'}
      put :update_verification_type, params: params
      consumer_person.reload

      expect(consumer_person.verification_types.where(:type_name => citizenship_type.type_name).first.update_reason).to eq("Expired")
    end

    context "redirection" do
      it "should redirect to back" do
        post :update_verification_type, params: { person_id: consumer_person.id }
        expect(response).to redirect_to "http://test.com"
      end
    end

    context "verification reason inputs" do
      it "should not update verification attributes without verification reason" do
        post :update_verification_type, params: { person_id: consumer_person.id,
                                                  verification_type: citizenship_type.id,
                                                  verification_reason: "",
                                                  admin_action: "verify"}
        consumer_person.reload
        expect(consumer_person.consumer_role.lawful_presence_update_reason).to eq nil
      end

      VlpDocument::VERIFICATION_REASONS.each do |reason|
        it_behaves_like "update verification type", "citizenship_type", reason, "verify", "lawful_presence_update_reason", reason
      end
    end

    context 'admin_rejected a verification_type' do
      let!(:verification_type) do
        consumer_person.verification_types.create!(type_name: 'Citizenship', validation_status: 'unverified')
      end

      let(:input_params) do
        { person_id: consumer_person.id,
          verification_type: verification_type.id,
          admin_action: 'return_for_deficiency',
          family_member_id: family.primary_applicant.id,
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
    let!(:permission) { FactoryBot.create(:permission, :super_admin) }
    let!(:update_admin) { admin_person.hbx_staff_role.update_attributes(permission_id: permission.id) }

    before :each do
      request.env["HTTP_REFERER"] = "http://test.com"
      consumer_person.verification_types = [ssn_type, local_type, citizenship_type, native_type, immigration_type]
      sign_in admin_user
    end

    shared_examples_for "update ridp verification type" do |type, reason, admin_action, updated_attr, result|
      it "updates #{updated_attr} for #{type} to #{result} with #{admin_action} admin action" do
        post :update_ridp_verification_type, params: { person_id: consumer_person.id,
                                                       ridp_verification_type: type,
                                                       verification_reason: reason,
                                                       admin_action: admin_action}
        consumer_person.reload
        expect(consumer_person.consumer_role.send(updated_attr)).to eq(result)
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
        post :update_ridp_verification_type, params: { person_id: consumer_person.id }
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "GET cartafact_download" do
    let!(:document) {consumer_person.documents.create}
    let(:tempfile) do
      tf = Tempfile.new('test.pdf')
      tf.write("DATA GOES HERE")
      tf.rewind
      tf
    end

    context 'when broker role' do
      context 'is authorized' do
        before(:each) do
          family.broker_agency_accounts << BenefitSponsors::Accounts::BrokerAgencyAccount.new(benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id,
                                                                                              start_on: Time.now,
                                                                                              writing_agent_id: broker_role.id,
                                                                                              is_active: true)
          family.reload
          allow(Operations::Documents::Download).to receive(:call).and_return(Dry::Monads::Success(tempfile))
          sign_in broker_role_user
        end

        it 'should be able to download' do
          get :cartafact_download, params: {model: "Person", model_id: consumer_person.id, relation: "documents", relation_id: document.id}
          expect(response.status).to eq(200)
          expect(response.headers["Content-Disposition"]).to eq 'attachment'
        end

        it 'downloads document even if Consumer is not RIDP verified' do
          consumer_person.consumer_role.update_attributes!(identity_validation: 'na', application_validation: 'na')
          get :cartafact_download, params: {model: "Person", model_id: consumer_person.id, relation: "documents", relation_id: document.id}
          expect(response.status).to eq(200)
          expect(response.headers["Content-Disposition"]).to eq 'attachment'
        end
      end

      context 'is not authorized' do
        it 'should not be able to download' do
          sign_in broker_role_user
          get :cartafact_download, params: {model: "Person", model_id: consumer_person.id, relation: "documents", relation_id: document.id}
          expect(flash[:error]).to eq("Access not allowed for person_policy.can_download_document?, (Pundit policy)")
        end
      end
    end

    context 'when hbx staff role' do
      context 'is authorized' do
        it 'should be able to download' do
          allow(Operations::Documents::Download).to receive(:call).and_return(Dry::Monads::Success(tempfile))
          sign_in admin_user
          get :cartafact_download, params: {model: "Person", model_id: consumer_person.id, relation: "documents", relation_id: document.id}
          expect(response.status).to eq(200)
          expect(response.headers["Content-Disposition"]).to eq 'attachment'
        end
      end

      context 'is not authorized' do
        let!(:permission) { FactoryBot.create(:permission, :hbx_csr_tier1, modify_family: false) }
        let!(:update_admin) { admin_person.hbx_staff_role.update_attributes(permission_id: permission.id) }

        it 'should not be able to download' do
          sign_in admin_user
          get :cartafact_download, params: {model: "Person", model_id: consumer_person.id, relation: "documents", relation_id: document.id}
          expect(flash[:error]).to eq("Access not allowed for person_policy.can_download_document?, (Pundit policy)")
        end
      end
    end

    context 'when consumer role' do
      it 'should be able to download' do
        allow(Operations::Documents::Download).to receive(:call).and_return(Dry::Monads::Success(tempfile))
        sign_in consumer_user
        get :cartafact_download, params: {model: "Person", model_id: consumer_person.id, relation: "documents", relation_id: document.id}
        expect(response.status).to eq(200)
        expect(response.headers["Content-Disposition"]).to eq 'attachment'
      end
    end

    context 'unauthorized consumer' do
      it 'should not be able to download' do
        sign_in fake_user
        get :cartafact_download, params: {model: "Person", model_id: consumer_person.id, relation: "documents", relation_id: document.id}
        expect(flash[:error]).to eq("Access not allowed for person_policy.can_download_document?, (Pundit policy)")
      end
    end
  end

  describe "GET authorized_download" do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:profile) { benefit_sponsorship.organization.profiles.first }
    let(:employer_staff_person) { FactoryBot.create(:person) }
    let(:employer_staff_user) { FactoryBot.create(:user, person: employer_staff_person) }
    let(:er_staff_role) { FactoryBot.create(:benefit_sponsor_employer_staff_role, benefit_sponsor_employer_profile_id: benefit_sponsorship.organization.employer_profile.id) }
    let(:document) {profile.documents.create(identifier: "urn:opentest:terms:t1:test_storage:t3:bucket:test-test-id-verification-test#sample-key")}

    context 'employer staff role' do
      context 'for a user with POC role' do
        before do
          employer_staff_person.employer_staff_roles << er_staff_role
          employer_staff_person.save!
          sign_in employer_staff_user
        end

        it 'current user employer should be able to download' do
          get :authorized_download, params: {model: "BenefitSponsors::Organizations::AcaShopDcEmployerProfile", model_id: profile.id, relation: "documents", relation_id: document.id}
          expect(response).to be_successful
        end
      end

      context 'for a user without POC role' do
        before do
          sign_in employer_staff_user
        end

        it 'current user employer should be able to download' do
          get :authorized_download, params: {model: "BenefitSponsors::Organizations::AcaShopDcEmployerProfile", model_id: profile.id, relation: "documents", relation_id: document.id}
          expect(response).to have_http_status(:found)
          expect(flash[:error]).to eq("Access not allowed for benefit_sponsors/employer_profile_policy.can_download_document?, (Pundit policy)")
        end
      end
    end

    context 'broker role' do
      context 'with authorized account' do
        before do
          profile.broker_agency_accounts << BenefitSponsors::Accounts::BrokerAgencyAccount.new(benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id,
                                                                                               writing_agent_id: broker_role.id,
                                                                                               start_on: Time.now,
                                                                                               is_active: true)
          sign_in broker_role_user
        end

        it 'broker should be able to download' do
          get :authorized_download, params: {model: "BenefitSponsors::Organizations::AcaShopDcEmployerProfile", model_id: profile.id, relation: "documents", relation_id: document.id}
          expect(response).to be_successful
        end
      end

      context 'without authorized account' do
        before do
          sign_in broker_role_user
        end

        it 'broker should be able to download' do
          get :authorized_download, params: {model: "BenefitSponsors::Organizations::AcaShopDcEmployerProfile", model_id: profile.id, relation: "documents", relation_id: document.id}
          expect(response).to have_http_status(:found)
          expect(flash[:error]).to eq("Access not allowed for benefit_sponsors/employer_profile_policy.can_download_document?, (Pundit policy)")
        end
      end
    end

    context 'hbx staff role' do
      context 'with permission to access' do
        before do
          sign_in admin_user
        end

        it 'hbx staff should be able to download' do
          get :authorized_download, params: {model: "BenefitSponsors::Organizations::AcaShopDcEmployerProfile", model_id: profile.id, relation: "documents", relation_id: document.id}
          expect(response).to be_successful
        end
      end

      context 'without permission to access' do
        let!(:permission) { FactoryBot.create(:permission, :hbx_csr_tier1, modify_employer: false) }
        let!(:update_admin) { admin_person.hbx_staff_role.update_attributes(permission_id: permission.id) }

        before do
          sign_in admin_user
        end

        it 'hbx staff should be able to download' do
          get :authorized_download, params: {model: "BenefitSponsors::Organizations::AcaShopDcEmployerProfile", model_id: profile.id, relation: "documents", relation_id: document.id}
          expect(response).to have_http_status(:found)
          expect(flash[:error]).to eq("Access not allowed for benefit_sponsors/employer_profile_policy.can_download_document?, (Pundit policy)")
        end
      end
    end
  end

  describe "GET employees_template_download" do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:profile) { benefit_sponsorship.organization.profiles.first }
    let(:employer_staff_person) { FactoryBot.create(:person) }
    let(:employer_staff_user) { FactoryBot.create(:user, person: employer_staff_person) }
    let(:er_staff_role) { FactoryBot.create(:benefit_sponsor_employer_staff_role, benefit_sponsor_employer_profile_id: benefit_sponsorship.organization.employer_profile.id) }
    let(:document) {profile.documents.create(identifier: "urn:opentest:terms:t1:test_storage:t3:bucket:test-test-id-verification-test#sample-key")}

    context 'employer staff role' do
      context 'for a user with POC role' do
        before do
          employer_staff_person.employer_staff_roles << er_staff_role
          employer_staff_person.save!
          sign_in employer_staff_user
        end

        it 'current user employer should be able to download' do
          get :employees_template_download
          expect(response).to be_successful
        end
      end

      context 'for a user without POC role' do

        before do
          sign_in employer_staff_user
        end

        it 'current user without employer staff role should not be able to download' do
          get :employees_template_download
          expect(response).to have_http_status(:found)
          expect(flash[:error]).to eq("Access not allowed for user_policy.can_download_employees_template?, (Pundit policy)")
        end
      end
    end

    context 'broker role' do
      context 'with authorized account' do
        before do
          profile.broker_agency_accounts << BenefitSponsors::Accounts::BrokerAgencyAccount.new(benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id,
                                                                                               writing_agent_id: broker_role.id,
                                                                                               start_on: Time.now,
                                                                                               is_active: true)
          sign_in broker_role_user
        end

        it 'broker should be able to download' do
          get :employees_template_download
          expect(response).to be_successful
        end
      end

      context 'with inactive broker role' do
        before do
          broker_role.update!(aasm_state: 'inactive')
          sign_in broker_role_user
        end

        it 'broker should be able to download' do
          get :employees_template_download
          expect(response).to have_http_status(:found)
          expect(flash[:error]).to eq("Access not allowed for user_policy.can_download_employees_template?, (Pundit policy)")
        end
      end
    end

    context 'hbx staff role' do
      context 'with permission to access' do
        before do
          sign_in admin_user
        end

        it 'hbx staff should be able to download' do
          get :employees_template_download
          expect(response).to be_successful
        end
      end
    end
  end

  describe "GET product_sbc_download" do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:profile) { benefit_sponsorship.organization.profiles.first }
    let(:employee_person) { FactoryBot.create(:person, :with_family, :with_employee_role) }
    let(:census_employee) { FactoryBot.create(:census_employee, employer_profile: profile, employee_role_id: person.employee_role.id) }
    let(:employee_user) { FactoryBot.create(:user, person: employee_person) }
    let(:product) do
      product = FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')
      product.create_sbc_document(identifier: "urn:opentest:terms:t1:test_storage:t3:bucket:test-test-id-verification-test#sample-key")
      product.save
      product
    end

    context 'employee role' do
      context 'for a user with employee role' do
        it 'current user employer should be able to download' do
          sign_in employee_user

          get :product_sbc_download, params: { document_id: product.sbc_document.id, product_id: product.id }
          expect(response).to be_successful
        end
      end

      context 'for a user without any role' do
        let(:user_without_roles) { FactoryBot.create(:user, person: FactoryBot.create(:person)) }
        before do
          sign_in user_without_roles
        end

        it 'current user without any role should not be able to download' do
          get :product_sbc_download, params: { document_id: product.sbc_document.id, product_id: product.id }
          expect(response).to have_http_status(:found)
          expect(flash[:error]).to eq("Access not allowed for person_policy.can_download_sbc_documents?, (Pundit policy)")
        end
      end
    end

    context 'broker role' do
      context 'with authorized account' do
        before do
          broker_agency_profile.update!(market_kind: 'both')
          employee_person.primary_family.broker_agency_accounts << BenefitSponsors::Accounts::BrokerAgencyAccount.new(benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id,
                                                                                                                      writing_agent_id: broker_role.id,
                                                                                                                      start_on: Time.now,
                                                                                                                      is_active: true)
          sign_in broker_role_user
        end

        it 'broker should be able to download' do
          get :product_sbc_download, params: { document_id: product.sbc_document.id, product_id: product.id }, session: { person_id: employee_person.id }
          expect(response).to be_successful
        end
      end

      context 'with inactive broker role' do
        before do
          broker_role.update!(aasm_state: 'inactive')
          sign_in broker_role_user
        end

        it 'broker should be able to download' do
          get :product_sbc_download, params: { document_id: product.sbc_document.id, product_id: product.id }, session: { person_id: employee_person.id }
          expect(response).to have_http_status(:found)
          expect(flash[:error]).to eq("Access not allowed for person_policy.can_download_sbc_documents?, (Pundit policy)")
        end
      end
    end

    context 'hbx staff role' do
      context 'with permission to access' do
        before do
          sign_in admin_user
        end

        it 'hbx staff should be able to download' do
          get :product_sbc_download, params: { document_id: product.sbc_document.id, product_id: product.id }
          expect(response).to be_successful
        end
      end
    end
  end
end
