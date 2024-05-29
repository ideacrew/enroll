# frozen_string_literal: true

require 'rails_helper'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  RSpec.describe FinancialAssistance::ApplicantsController, dbclean: :after_each, type: :controller do

    before :all do
      DatabaseCleaner.clean
    end

    routes { FinancialAssistance::Engine.routes }

    let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
    let(:user) { FactoryBot.create(:user, person: person) }
    let(:consumer_role) { person.consumer_role }
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:primary_family_member) { family.primary_family_member }
    let(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id) }
    let(:applicant) do
      FactoryBot.create(
        :financial_assistance_applicant,
        application: application,
        family_member_id: primary_family_member.id,
        person_hbx_id: user.person.hbx_id
      )
    end

    let(:permission) { FactoryBot.create(:permission, :developer) }
    let(:developer_person) { FactoryBot.create(:person, :with_hbx_staff_role) }
    let(:user_with_developer_role) { FactoryBot.create(:user, person: developer_person) }

    before do
      developer_person.hbx_staff_role.update_attributes(permission_id: permission.id, subrole: permission.name)
      sign_in(user_with_developer_role)
      session[:person_id] = person.id
    end

    describe '#age_of_applicant' do
      let(:params) { { application_id: application.id, applicant_id: applicant.id } }

      context 'logged in user has developer role' do
        it 'denies access and redirects to a different path' do
          applicant
          get :age_of_applicant, params: params
          expect(flash[:error]).to eq(
            'Access not allowed for financial_assistance/applicant_policy.age_of_applicant?, (Pundit policy)'
          )
        end
      end
    end

    describe '#applicant_is_eligible_for_joint_filing' do
      let(:params) { { application_id: application.id, applicant_id: applicant.id } }

      context 'logged in user has developer role' do
        it 'denies access and redirects to a different path' do
          applicant
          get :applicant_is_eligible_for_joint_filing, params: params
          expect(flash[:error]).to eq(
            'Access not allowed for financial_assistance/applicant_policy.applicant_is_eligible_for_joint_filing?, (Pundit policy)'
          )
        end
      end
    end

    describe '#other_questions' do
      let(:params) { { application_id: application.id, id: applicant.id } }

      context 'logged in user has developer role' do
        it 'denies access and redirects to a different path' do
          applicant
          get :other_questions, params: params
          expect(flash[:error]).to eq(
            'Access not allowed for financial_assistance/applicant_policy.other_questions?, (Pundit policy)'
          )
        end
      end
    end

    describe '#save_questions' do
      let(:params) { { application_id: application.id, id: applicant.id } }

      context 'logged in user has developer role' do
        it 'denies access and redirects to a different path' do
          applicant
          get :save_questions, params: params
          expect(flash[:error]).to eq(
            'Access not allowed for financial_assistance/applicant_policy.save_questions?, (Pundit policy)'
          )
        end
      end
    end

    describe '#tax_info' do
      let(:params) { { application_id: application.id, id: applicant.id } }

      context 'logged in user has developer role' do
        it 'denies access and redirects to a different path' do
          applicant
          get :tax_info, params: params
          expect(flash[:error]).to eq(
            'Access not allowed for financial_assistance/applicant_policy.tax_info?, (Pundit policy)'
          )
        end
      end
    end

    describe '#save_tax_info' do
      let(:params) { { application_id: application.id, id: applicant.id } }

      context 'logged in user has developer role' do
        it 'denies access and redirects to a different path' do
          applicant
          get :save_tax_info, params: params
          expect(flash[:error]).to eq(
            'Access not allowed for financial_assistance/applicant_policy.save_tax_info?, (Pundit policy)'
          )
        end
      end
    end

    describe '#immigration_document_options' do
      context 'logged in user has developer role' do
        context 'with target_type and target_id in input params' do
          let(:params) do
            {
              application_id: application.id,
              applicant_id: applicant.id,
              target_id: applicant.id,
              target_type: 'FinancialAssistance::Applicant'
            }
          end

          it 'denies access and redirects to a different path' do
            applicant
            get :immigration_document_options, params: params
            expect(flash[:error]).to eq(
              'Access not allowed for financial_assistance/applicant_policy.immigration_document_options?, (Pundit policy)'
            )
          end
        end

        context 'without target_type, target_id and applicant_id in input params' do
          let(:params) { { application_id: application.id } }

          it 'denies access and redirects to a different path' do
            applicant
            get :immigration_document_options, params: params
            expect(flash[:error]).to eq(
              'Access not allowed for financial_assistance/application_policy.new?, (Pundit policy)'
            )
          end
        end
      end
    end

    describe '#update' do
      let(:params) { { application_id: application.id, id: applicant.id } }

      context 'logged in user has developer role' do
        it 'denies access and redirects to a different path' do
          applicant
          get :update, params: params
          expect(flash[:error]).to eq(
            'Access not allowed for financial_assistance/applicant_policy.update?, (Pundit policy)'
          )
        end
      end
    end

    describe '#destroy' do
      let(:params) { { application_id: application.id, id: applicant.id } }

      context 'logged in user has developer role' do
        it 'denies access and redirects to a different path' do
          applicant
          delete :destroy, params: params
          expect(flash[:error]).to eq(
            'Access not allowed for financial_assistance/applicant_policy.destroy?, (Pundit policy)'
          )
        end
      end
    end

    describe '#step' do
      let(:params) { { application_id: application.id, id: applicant.id } }

      context 'logged in user has developer role' do
        it 'denies access and redirects to a different path' do
          applicant
          put :step, params: params
          expect(flash[:error]).to eq(
            'Access not allowed for financial_assistance/applicant_policy.step?, (Pundit policy)'
          )
        end
      end
    end

    describe '#create' do
      let(:params) { { application_id: application.id } }

      context 'logged in user has developer role' do
        it 'denies access and redirects to a different path' do
          applicant
          post :create, params: params
          expect(flash[:error]).to eq(
            'Access not allowed for financial_assistance/application_policy.create?, (Pundit policy)'
          )
        end
      end
    end

    describe '#edit' do
      let(:params) { { application_id: application.id, id: applicant.id } }

      context 'logged in user has developer role' do
        it 'denies access and redirects to a different path' do
          applicant
          get :edit, params: params
          expect(flash[:error]).to eq(
            'Access not allowed for financial_assistance/applicant_policy.edit?, (Pundit policy)'
          )
        end
      end
    end
  end
end
