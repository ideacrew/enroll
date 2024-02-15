# frozen_string_literal: true

RSpec.describe FinancialAssistance::VerificationDocumentsController, type: :controller do
  routes { FinancialAssistance::Engine.routes }
  let!(:fake_person) { FactoryBot.create(:person, :with_consumer_role) }
  let!(:fake_user) {FactoryBot.create(:user, :person => fake_person)}
  let!(:fake_family) { FactoryBot.create(:family, :with_primary_family_member, person: fake_person) }
  let!(:fake_family_member) { fake_family.family_members.first }

  let!(:admin_person) { FactoryBot.create(:person, :with_hbx_staff_role) }
  let!(:admin_user) {FactoryBot.create(:user, :with_hbx_staff_role, :person => admin_person)}
  let!(:permission) { FactoryBot.create(:permission, :super_admin) }
  let!(:update_admin) { admin_person.hbx_staff_role.update_attributes(permission_id: permission.id) }

  let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let!(:associated_user) {FactoryBot.create(:user, :person => person)}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:family_member) { family.family_members.first }

  let!(:application) do
    FactoryBot.create(
      :application,
      family_id: family.id,
      aasm_state: 'determined',
      assistance_year: TimeKeeper.date_of_record.year,
      effective_date: Date.today
    )
  end

  let!(:applicant) do
    applicant = FactoryBot.create(:financial_assistance_applicant,
                                  application: application,
                                  is_primary_applicant: true,
                                  ssn: person.ssn,
                                  dob: person.dob,
                                  first_name: person.first_name,
                                  last_name: person.last_name,
                                  gender: person.gender,
                                  person_hbx_id: person.hbx_id,
                                  family_member_id: family_member.id)
    applicant
  end

  let(:esi_evidence) do
    applicant.create_esi_evidence(
      key: :esi_mec,
      title: 'Esi',
      aasm_state: 'pending',
      due_on: nil,
      verification_outstanding: false,
      is_satisfied: true
    )
  end


  context 'admin' do
    before do
      sign_in(admin_user)
    end

    context 'POST #upload' do
      let!(:tempfile) { Tempfile.new(['test_document', '.pdf']) }
      let!(:file) { [Rack::Test::UploadedFile.new(tempfile.path, 'application/pdf')] }
      let!(:bucket_name) { 'id-verification' }
      let!(:doc_id) { "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}sample-key" }
      let!(:params) { { "applicant_id" => applicant.id, "evidence" => esi_evidence.id, "evidence_kind" => "esi_evidence", "application_id" => application.id, file: file} }

      context 'with valid params' do
        before do
          allow(Aws::S3Storage).to receive(:save).and_return(doc_id)
        end

        it 'uploads a new VerificationDocument' do
          post :upload, params: params
          expect(flash[:notice]).to eq("File Saved")
        end
      end

      context 'with invalid params' do
        before do
          allow(Aws::S3Storage).to receive(:save).and_return(nil)
        end

        let!(:params) { { "applicant_id" => applicant.id, "evidence" => esi_evidence.id, "evidence_kind" => "esi_evidence", "application_id" => application.id, file: file} }

        it 'does not upload a new VerificationDocument' do
          post :upload, params: params
          expect(flash[:error]).to eq("Could not save file")
        end
      end
    end

    context 'GET #download' do
      context 'with valid params' do

        before do
          allow(controller).to receive(:get_document).with('sample-key').and_return(Document.new)
        end

        let!(:params) {{"key" => "sample-key", "evidence_kind" => "esi_evidence", "application_id" => application.id, "applicant_id" => applicant.id}}

        it 'downloads the requested verification document' do
          get :download, params: params
          expect(response).to be_successful
        end
      end
    end

    context 'DELETE #destroy' do
      let!(:document) { esi_evidence.documents.create}

      before do
        allow(controller).to receive(:get_document).with('sample-key').and_return(document)
      end

      let!(:params) do
        { "doc_key" => "sample-key", "doc_title" => "sample-key.Png", "evidence" => esi_evidence.id, "evidence_kind" => "esi_evidence", "application_id" => application.id, "applicant_id" => applicant.id}
      end

      it 'destroys the requested verification document' do
        expect do
          delete :destroy, params: params
        end.to change(esi_evidence.documents, :count).by(-1)
      end
    end
  end

  context 'associated_user' do
    before do
      sign_in(associated_user)
    end

    context 'POST #upload' do
      let!(:tempfile) { Tempfile.new(['test_document', '.pdf']) }
      let!(:file) { [Rack::Test::UploadedFile.new(tempfile.path, 'application/pdf')] }
      let!(:bucket_name) { 'id-verification' }
      let!(:doc_id) { "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}sample-key" }
      let!(:params) { { "applicant_id" => applicant.id, "evidence" => esi_evidence.id, "evidence_kind" => "esi_evidence", "application_id" => application.id, file: file} }

      context 'with valid params' do
        before do
          allow(Aws::S3Storage).to receive(:save).and_return(doc_id)
        end

        it 'uploads a new VerificationDocument' do
          post :upload, params: params
          expect(flash[:notice]).to eq("File Saved")
        end
      end
    end

    context 'GET #download' do
      let!(:document) { esi_evidence.documents.create}
      context 'with valid params' do
        before do
          allow(controller).to receive(:get_document).with('sample-key').and_return(document)
        end

        let!(:params) {{"key" => "sample-key", "evidence_kind" => "esi_evidence", "application_id" => application.id, "applicant_id" => applicant.id}}

        it 'downloads the requested verification document' do
          get :download, params: params
          expect(response).to be_successful
        end
      end
    end

    context 'DELETE #destroy' do
      let!(:document) { esi_evidence.documents.create}

      before do
        allow(controller).to receive(:get_document).with('sample-key').and_return(document)
      end

      let!(:params) do
        { "doc_key" => "sample-key", "doc_title" => "sample-key.Png", "evidence" => esi_evidence.id, "evidence_kind" => "esi_evidence", "application_id" => application.id, "applicant_id" => applicant.id}
      end

      it 'destroys the requested verification document' do
        expect do
          delete :destroy, params: params
        end.to change(esi_evidence.documents, :count).by(-1)
      end
    end
  end

  context 'unauthorized user' do
    before do
      sign_in(fake_user)
    end

    context 'POST #upload' do
      let!(:tempfile) { Tempfile.new(['test_document', '.pdf']) }
      let!(:file) { [Rack::Test::UploadedFile.new(tempfile.path, 'application/pdf')] }
      let!(:bucket_name) { 'id-verification' }
      let!(:doc_id) { "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}sample-key" }
      let!(:params) { { "applicant_id" => applicant.id, "evidence" => esi_evidence.id, "evidence_kind" => "esi_evidence", "application_id" => application.id, file: file} }

      context 'with unauthorized user' do

        before do
          allow(Aws::S3Storage).to receive(:save).and_return(doc_id)
        end

        it 'returns failure' do
          post :upload, params: params
          expect(flash[:error]).to eq("Access not allowed for eligibilities/evidence_policy.can_upload?, (Pundit policy)")
        end
      end
    end

    context 'GET #download' do
      let!(:document) { esi_evidence.documents.create}
      context 'with unauthorized user' do

        before do
          allow(controller).to receive(:get_document).with('sample-key').and_return(document)
        end

        let!(:params) {{"key" => "sample-key", "evidence_kind" => "esi_evidence", "application_id" => application.id, "applicant_id" => applicant.id}}

        it 'shoudl not download the requested verification document' do
          get :download, params: params
          expect(response).to have_http_status(:found)
          expect(flash[:error]).to eq("Access not allowed for document_policy.can_download?, (Pundit policy)")
        end
      end
    end

    context 'DELETE #destroy' do
      let!(:document) { esi_evidence.documents.create}

      before do
        allow(controller).to receive(:get_document).with('sample-key').and_return(document)
      end

      let!(:params) do
        { "doc_key" => "sample-key", "doc_title" => "sample-key.Png", "evidence" => esi_evidence.id, "evidence_kind" => "esi_evidence", "application_id" => application.id, "applicant_id" => applicant.id}
      end

      it 'should not destroy' do
        expect do
          delete :destroy, params: params
        end.to change(esi_evidence.documents, :count).by(0)
      end
    end
  end

  context 'broker logged in' do
    let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let!(:associated_user) {FactoryBot.create(:user, :person => person)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let!(:family_member) { family.family_members.first }
    let!(:broker_user) {FactoryBot.create(:user, :person => writing_agent.person, roles: ['broker_role', 'broker_agency_staff_role'])}
    let(:broker_agency_profile) { FactoryBot.build(:benefit_sponsors_organizations_broker_agency_profile)}
    let(:writing_agent)         { FactoryBot.create(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id) }
    let(:assister)  do
      assister = FactoryBot.build(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, npn: "SMECDOA00")
      assister.save(validate: false)
      assister
    end

    context 'hired by family' do
      before(:each) do
        family.broker_agency_accounts << BenefitSponsors::Accounts::BrokerAgencyAccount.new(benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id,
                                                                                            writing_agent_id: writing_agent.id,
                                                                                            start_on: Time.now,
                                                                                            is_active: true)
        family.reload

        sign_in(broker_user)
      end


      context 'POST #upload' do
        let!(:tempfile) { Tempfile.new(['test_document', '.pdf']) }
        let!(:file) { [Rack::Test::UploadedFile.new(tempfile.path, 'application/pdf')] }
        let!(:bucket_name) { 'id-verification' }
        let!(:doc_id) { "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}sample-key" }
        let!(:params) { { "applicant_id" => applicant.id, "evidence" => esi_evidence.id, "evidence_kind" => "esi_evidence", "application_id" => application.id, file: file} }

        context 'with valid params' do
          before do
            allow(Aws::S3Storage).to receive(:save).and_return(doc_id)
          end

          it 'uploads a new VerificationDocument' do
            post :upload, params: params
            expect(flash[:notice]).to eq("File Saved")
          end
        end
      end

      context 'GET #download' do
        let!(:document) { esi_evidence.documents.create}
        context 'with valid params' do
          before do
            allow(controller).to receive(:get_document).with('sample-key').and_return(document)
          end

          let!(:params) {{"key" => "sample-key", "evidence_kind" => "esi_evidence", "application_id" => application.id, "applicant_id" => applicant.id}}

          it 'downloads the requested verification document' do
            get :download, params: params
            expect(response).to be_successful
          end
        end
      end

      context 'DELETE #destroy' do
        let!(:document) { esi_evidence.documents.create}

        before do
          allow(controller).to receive(:get_document).with('sample-key').and_return(document)
        end

        let!(:params) do
          { "doc_key" => "sample-key", "doc_title" => "sample-key.Png", "evidence" => esi_evidence.id, "evidence_kind" => "esi_evidence", "application_id" => application.id, "applicant_id" => applicant.id}
        end

        it 'destroys the requested verification document' do
          expect do
            delete :destroy, params: params
          end.to change(esi_evidence.documents, :count).by(-1)
        end
      end
    end

    context 'not hired by family' do
      before(:each) do
        sign_in(broker_user)
      end

      context 'POST #upload' do
        let!(:tempfile) { Tempfile.new(['test_document', '.pdf']) }
        let!(:file) { [Rack::Test::UploadedFile.new(tempfile.path, 'application/pdf')] }
        let!(:bucket_name) { 'id-verification' }
        let!(:doc_id) { "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}sample-key" }
        let!(:params) { { "applicant_id" => applicant.id, "evidence" => esi_evidence.id, "evidence_kind" => "esi_evidence", "application_id" => application.id, file: file} }

        context 'with valid params' do
          before do
            allow(Aws::S3Storage).to receive(:save).and_return(doc_id)
          end

          it 'returns failure' do
            post :upload, params: params
            expect(flash[:error]).to eq("Access not allowed for eligibilities/evidence_policy.can_upload?, (Pundit policy)")
          end
        end
      end

      context 'GET #download' do
        let!(:document) { esi_evidence.documents.create}
        context 'with valid params' do
          before do
            allow(controller).to receive(:get_document).with('sample-key').and_return(document)
          end

          let!(:params) {{"key" => "sample-key", "evidence_kind" => "esi_evidence", "application_id" => application.id, "applicant_id" => applicant.id}}

          it 'downloads the requested verification document' do
            get :download, params: params
            expect(response).to have_http_status(:found)
            expect(flash[:error]).to eq("Access not allowed for document_policy.can_download?, (Pundit policy)")
          end
        end
      end

      context 'DELETE #destroy' do
        let!(:document) { esi_evidence.documents.create}

        before do
          allow(controller).to receive(:get_document).with('sample-key').and_return(document)
        end

        let!(:params) do
          { "doc_key" => "sample-key", "doc_title" => "sample-key.Png", "evidence" => esi_evidence.id, "evidence_kind" => "esi_evidence", "application_id" => application.id, "applicant_id" => applicant.id}
        end

        it 'destroys the requested verification document' do
          expect do
            delete :destroy, params: params
          end.to change(esi_evidence.documents, :count).by(0)
        end
      end
    end
  end
end