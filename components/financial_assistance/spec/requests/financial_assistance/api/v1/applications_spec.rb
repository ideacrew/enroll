# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'applications', dbclean: :around_each, type: :request do
  include FinancialAssistance::Engine.routes.url_helpers

  let(:person) { FactoryBot.create(:person, :with_consumer_role)}
  let!(:user) { FactoryBot.create(:user, :person => person) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

  before(:each) do
    sign_in user
  end

  path '/financial_assistance/api/v1/applications' do
    get 'retreives all applications' do
      tags FinancialAssistance::Application
      produces 'application/json'

      response '200', 'index' do
        schema type: :array,
               items: {
                 '$ref' => '#/components/schemas/application'
               }

        let!(:application) { FactoryBot.create :financial_assistance_application, :with_applicants, family_id: family.id, aasm_state: 'determined' }

        run_test!

      end
    end

    post 'creates an application' do
      tags 'FinancialAssistance::Application'
      consumes 'application/json'
      # parameter name: 'Authorization', in: :header, type: :string, default: 'Bearer c36e6eadde881ca7'
      parameter name: :application, in: :body, schema: {
        type: :object,
        properties: {
          applicants_attributes: {
            type: :object,
            properties: {
              is_ssn_applied: { type: :boolean },
              non_ssn_apply_reason: { type: :string },
              is_pregnant: { type: :boolean },
              pregnancy_due_on: { type: :string },
              children_expected_count: { type: :string },
              is_post_partum_period: { type: :boolean },
              pregnancy_end_on: { type: :string },
              is_former_foster_care: { type: :boolean },
              foster_care_us_state: { type: :string },
              age_left_foster_care: { type: :string },
              is_student: { type: :boolean },
              student_kind: { type: :string },
              student_status_end_on: { type: :string },
              student_school_kind: { type: :string },
              is_self_attested_blind: { type: :boolean },
              has_daily_living_help: { type: :boolean },
              need_help_paying_bills: { type: :boolean }
            }
          }
        }
      }

      response '200', :created do
        schema type: :object,
               properties: {
                 '$ref' => '#/components/schemas/application'
               }

        let(:application) do
          {
            application: {
              applicants_attributes: [{
                is_ssn_applied: 'true'
              }]
            }
          }
        end

        run_test!
      end

      response '400', :bad_request do
        schema  type: :object,
                properties: {
                  error: {
                    type: :array,
                    items: {
                      type: :string
                    }
                  }
                }
        let(:application) do
          {
            application: {
              applicants_attributes: [{
                tax_filer_kind: 'fake'
              }]
            }
          }
        end

        run_test!
      end

    end
  end

  path '/financial_assistance/api/v1/applications/{id}' do
    put 'update an application' do
      tags 'FinancialAssistance::Application'
      consumes 'application/json'
      parameter name: :id, in: :path, type: :string
      parameter name: :application, in: :body, schema: {
        type: :object,
        properties: {
          applicants_attributes: {
            type: :object,
            properties: {
              is_ssn_applied: { type: :boolean },
              non_ssn_apply_reason: { type: :string },
              is_pregnant: { type: :boolean },
              pregnancy_due_on: { type: :string },
              children_expected_count: { type: :string },
              is_post_partum_period: { type: :boolean },
              pregnancy_end_on: { type: :string },
              is_former_foster_care: { type: :boolean },
              foster_care_us_state: { type: :string },
              age_left_foster_care: { type: :string },
              is_student: { type: :boolean },
              student_kind: { type: :string },
              student_status_end_on: { type: :string },
              student_school_kind: { type: :string },
              is_self_attested_blind: { type: :boolean },
              has_daily_living_help: { type: :boolean },
              need_help_paying_bills: { type: :boolean }
            }
          }
        }
      }

      response '200', :success do
        schema type: :object,
               properties: {
                 '$ref' => '#/components/schemas/application'
               }

        let!(:id) { create(:financial_assistance_application, :with_applicants, family_id: family.id).id }
        let(:application) { { application: { applicants_attributes: [{ is_ssn_applied: 'false' }] } } }

        run_test!
      end

      response '400', :bad_request do
        schema  type: :object,
                properties: {
                  error: {
                    type: :array,
                    items: {
                      type: :string
                    }
                  }
                }

        let(:existing_application) { create(:financial_assistance_application, :with_applicants, family_id: family.id) }
        let(:id) { existing_application.id }
        let(:application) do
          {
            application: {
              applicants_attributes: [{
                id: existing_application.applicants.first.id,
                tax_filer_kind: 'fake'
              }]
            }
          }
        end

        run_test!
      end
    end

    delete 'Delete application by id' do
      tags 'FinancialAssistance::Application'
      parameter name: :id, in: :path, type: :string
      response '204', :no_content do
        let!(:id) { create(:financial_assistance_application, :with_applicants, family_id: family.id).id }
        run_test!
      end
    end
  end
end