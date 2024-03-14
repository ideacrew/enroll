# frozen_string_literal: true

RSpec.describe FinancialAssistance::ApplicationsController, dbclean: :after_each, type: :controller do
  routes { FinancialAssistance::Engine.routes }

  describe 'pundit policy authorization checks' do
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

    before do
      person.consumer_role.move_identity_documents_to_verified
    end

    context 'admin with permissions' do
      before do
        sign_in(admin_user)
      end

      context 'GET #copy' do
        context 'with valid params' do
          let!(:params) {{ id: application.id }}


          it 'copies application' do
            get :copy, params: params
            copy_app = FinancialAssistance::Application.where(family_id: family.id).reject {|app| [application.id].include? app.id}.first
            expect(response).to redirect_to(edit_application_path(copy_app.id))
          end
        end

        context 'with invalid params' do
          let!(:params) {{ id: "test" }}

          it 'returns application not found error' do
            expect { get :copy, params: params }.to raise_error
          end
        end
      end

      context 'GET #review_and_submit' do
        context 'with valid params' do
          let!(:params) {{ id: application.id }}

          it 'returns success' do
            application.update_attributes(:aasm_state => "draft")
            get :review_and_submit, params: params
            expect(response).to be_successful
          end
        end
      end

      context 'GET #review' do
        let!(:params) {{ id: application.id }}

        it 'returns success' do
          get :review, params: params
          expect(response).to be_successful
        end
      end

      context 'GET #index' do
        it 'returns success' do
          session[:person_id] = person.id
          get :index
          expect(response).to be_successful
        end
      end

      context "GET checklist_pdf" do
        it 'returns success' do
          get :checklist_pdf
          expect(response).to be_successful
        end
      end
    end

    context 'admin without permissions' do
      let!(:permission) { FactoryBot.create(:permission, :developer) }

      before do
        sign_in(admin_user)
      end

      context 'GET #copy' do
        context 'with valid params' do
          let!(:params) {{ id: application.id }}


          it 'does not copy application' do
            get :copy, params: params
            copy_app = FinancialAssistance::Application.where(family_id: family.id).reject {|app| [application.id].include? app.id}.first
            expect(copy_app.present?).to be_falsey
            expect(flash[:error]).to eq("Access not allowed for financial_assistance/application_policy.can_access_application?, (Pundit policy)")
          end
        end
      end

      context 'GET #review_and_submit' do
        context 'with valid params' do
          let!(:params) {{ id: application.id }}

          it 'returns authorization failure' do
            application.update_attributes(:aasm_state => "draft")
            get :review_and_submit, params: params
            expect(flash[:error]).to eq("Access not allowed for financial_assistance/application_policy.can_access_application?, (Pundit policy)")
          end
        end
      end

      context 'GET #review' do
        let!(:params) {{ id: application.id }}

        it 'returns authorization failure' do
          get :review, params: params
          expect(flash[:error]).to eq("Access not allowed for financial_assistance/application_policy.can_review?, (Pundit policy)")
        end
      end

      context 'GET #index' do
        it 'returns success' do
          session[:person_id] = person.id
          get :index
          expect(flash[:error]).to eq("Access not allowed for financial_assistance/application_policy.can_access_application?, (Pundit policy)")
        end
      end

      context "GET application_publish_error" do
        context "With missing family id" do
          it 'should find application and it is not authorized to view' do
            get :application_publish_error, params: { id: application.id }
            expect(assigns(:application)).to eq application
            expect(flash[:error]).to eq("Access not allowed for financial_assistance/application_policy.can_access_application?, (Pundit policy)")
          end
        end
      end
    end

    context 'user without roles' do
      let!(:person_without_role) { FactoryBot.create(:person) }
      let!(:user_without_role) { FactoryBot.create(:user, :person => person_without_role) }

      context "GET checklist_pdf" do
        it 'returns success' do
          sign_in(user_without_role)
          get :checklist_pdf
          expect(flash[:error]).to eq("Access not allowed for financial_assistance/application_policy.can_view_checklist_pdf?, (Pundit policy)")
        end
      end
    end

    context 'associated_user' do
      before do
        sign_in(associated_user)
      end

      context 'GET #copy' do
        context 'with valid params' do
          let!(:params) {{ id: application.id }}


          it 'copies application' do
            get :copy, params: params
            copy_app = FinancialAssistance::Application.where(family_id: family.id).reject {|app| [application.id].include? app.id}.first
            expect(response).to redirect_to(edit_application_path(copy_app.id))
          end
        end

        context 'with invalid params' do
          let!(:params) {{ id: "test" }}

          it 'returns application not found error' do
            expect { get :copy, params: params }.to raise_error
          end
        end
      end

      context 'GET #review_and_submit' do
        context 'with valid params' do
          let!(:params) {{ id: application.id }}

          it 'returns success' do
            application.update_attributes(:aasm_state => "draft")
            get :review_and_submit, params: params
            expect(response).to be_successful
          end
        end
      end

      context 'GET #review' do
        let!(:params) {{ id: application.id }}

        it 'returns success' do
          get :review, params: params
          expect(response).to be_successful
        end
      end
    end

    context 'unauthorized user' do
      let(:fake_person) { FactoryBot.create(:person, :with_consumer_role) }
      let(:fake_user) {FactoryBot.create(:user, :person => fake_person)}
      let!(:fake_family) { FactoryBot.create(:family, :with_primary_family_member, person: fake_person) }

      before do
        sign_in(fake_user)
      end

      context 'GET #copy' do
        context 'with valid params' do
          let!(:params) {{ id: application.id }}


          it 'returns application not found error for unauthorized user' do
            expect { get :copy, params: params }.to raise_error
          end
        end
      end

      context 'GET #review_and_submit' do
        context 'with valid params' do
          let!(:params) {{ id: application.id }}

          it 'returns application not found error for unauthorized user' do
            application.update_attributes(:aasm_state => "draft")
            expect { get :review_and_submit, params: params }.to raise_error
          end
        end
      end

      context 'GET #review' do
        let!(:params) {{ id: application.id }}

        it 'returns authorization failure' do
          get :review, params: params
          expect(flash[:error]).to eq("Access not allowed for financial_assistance/application_policy.can_review?, (Pundit policy)")
        end
      end

      context "GET application_publish_error" do
        context "With missing family id" do
          it 'should find application and it is not authorized to view' do
            expect { get :application_publish_error, params: params }.to raise_error
          end
        end
      end
    end
  end
end