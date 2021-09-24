# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::Renew, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  before :all do
    DatabaseCleaner.clean
  end

  let!(:person) do
    FactoryBot.create(:person,
                      :with_consumer_role,
                      dob: TimeKeeper.date_of_record - 40.years,
                      hbx_id: '100095')
  end
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:application10) do
    appli = FactoryBot.create(:financial_assistance_application,
                              :with_attestations,
                              hbx_id: '111000222',
                              family_id: family.id,
                              assistance_year: TimeKeeper.date_of_record.year,
                              is_requesting_voter_registration_application_in_mail: true,
                              is_renewal_authorized: true,
                              aasm_state: 'draft',
                              medicaid_terms: true,
                              report_change_terms: true,
                              medicaid_insurance_collection_terms: true,
                              parent_living_out_of_home_terms: false,
                              submission_terms: true,
                              full_medicaid_determination: true)
    appli.submit!
    appli
  end
  let!(:create_appli) do
    appli = FactoryBot.build(:financial_assistance_applicant,
                             :with_work_phone,
                             person_hbx_id: '100095',
                             is_primary_applicant: true,
                             first_name: 'Gerald',
                             last_name: 'Rivers',
                             citizen_status: 'us_citizen',
                             family_member_id: family.primary_applicant.id,
                             gender: 'male',
                             ethnicity: [],
                             dob: Date.new(Date.today.year - 22, Date.today.month, Date.today.day))
    appli.phones = [FactoryBot.build(:financial_assistance_phone,
                                     kind: 'work',
                                     area_code: '202',
                                     number: '1111111',
                                     full_phone_number: '2021111111',
                                     extension: '',
                                     primary: true)]
    application10.applicants.destroy_all
    application10.applicants = [appli]
    application10.save!
  end

  let(:event) { Success(double) }
  let(:obj) { ::FinancialAssistance::Operations::Applications::MedicaidGateway::PublishApplication.new }

  before do
    allow(obj.class).to receive(:new).and_return(obj)
    allow(obj).to receive(:build_event).and_return(event)
    allow(event.success).to receive(:publish).and_return(true)
  end

  context 'success' do
    context 'is_renewal_authorized set to true i.e. renewal authorized for next 5 years' do
      before do
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:haven_determination).and_return(true)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:verification_type_income_verification).and_return(true)
        @renewal_draft = ::FinancialAssistance::Operations::Applications::CreateRenewalDraft.new.call(
          { family_id: application10.family_id, renewal_year: application10.assistance_year.next }
        ).success
        @result = subject.call({ application_hbx_id: @renewal_draft.hbx_id })
        @renewed_app = @result.success
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should return application' do
        expect(@renewed_app).to be_a(::FinancialAssistance::Application)
      end

      it 'should return application with submitted' do
        expect(@renewed_app.submitted?).to be_truthy
      end

      it 'should return application with assistance_year' do
        expect(@renewed_app.assistance_year).to eq(application10.assistance_year.next)
      end
    end

    context 'is_renewal_authorized set to false with remaining years_to_renew' do
      before do
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:haven_determination).and_return(true)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:verification_type_income_verification).and_return(true)
        application10.update_attributes!({ is_renewal_authorized: false, years_to_renew: [1, 2, 3, 4, 5].sample })
        @renewal_draft = ::FinancialAssistance::Operations::Applications::CreateRenewalDraft.new.call(
          { family_id: application10.family_id, renewal_year: application10.assistance_year.next }
        ).success
        @result = subject.call({ application_hbx_id: @renewal_draft.hbx_id })
        @renewed_app = @result.success
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should return application' do
        expect(@renewed_app).to be_a(::FinancialAssistance::Application)
      end

      it 'should return application with submitted' do
        expect(@renewed_app.submitted?).to be_truthy
      end

      it 'should return application with assistance_year' do
        expect(@renewed_app.assistance_year).to eq(application10.assistance_year.next)
      end
    end
  end

  context 'failure' do
    context 'invalid input data' do
      before do
        @result = subject.call('test')
      end

      it 'should return failure with error message' do
        expect(@result.failure).to eq('Input params is not a hash: test')
      end
    end

    context 'for an application which is not in renewal_draft state' do
      shared_examples_for 'non renewal_draft state application' do |app_state|
        before do
          application10.update_attributes!(aasm_state: app_state)
          @result = subject.call({ application_hbx_id: application10.hbx_id })
        end

        it 'should return failure' do
          expect(@result).to be_failure
        end

        it "should return failure with error messasge for application with aasm_state: #{app_state}" do
          expect(@result.failure).to eq("Cannot generate renewal_draft for given application with aasm_state #{application10.aasm_state}. Application must be in renewal_draft state.")
        end
      end

      context 'failure because of application aasm_state' do
        it_behaves_like 'non renewal_draft state application', 'draft'
        it_behaves_like 'non renewal_draft state application', 'submitted'
        it_behaves_like 'non renewal_draft state application', 'determined'
        it_behaves_like 'non renewal_draft state application', 'determination_response_error'
      end
    end

    context 'ineligible application' do
      before do
        @renewal_draft = ::FinancialAssistance::Operations::Applications::CreateRenewalDraft.new.call(
          { family_id: application10.family_id, renewal_year: application10.assistance_year.next }
        ).success
      end

      context 'incomplete application by validation' do
        before do
          @renewal_draft.update_attributes!(us_state: nil)
          @result = subject.call({ application_hbx_id: @renewal_draft.hbx_id })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq("Application with hbx_id: #{@renewal_draft.hbx_id} is incomplete(validations/attestations) for submission.")
        end
      end

      context 'incomplete application by attestation' do
        before do
          @renewal_draft.update_attributes!(is_requesting_voter_registration_application_in_mail: nil)
          @result = subject.call({ application_hbx_id: @renewal_draft.hbx_id })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq("Application with hbx_id: #{@renewal_draft.hbx_id} is incomplete(validations/attestations) for submission.")
        end
      end

      context 'expired permission for renewal' do
        before do
          @renewal_draft.update_attributes!(renewal_base_year: @renewal_draft.assistance_year.pred)
          @result = subject.call({ application_hbx_id: @renewal_draft.hbx_id })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq("Expired Submission or unable to submit the application for given application hbx_id: #{@renewal_draft.hbx_id}")
        end

        it 'should also transition application to submission_pending' do
          expect(@renewal_draft.reload.submission_pending?).to be_truthy
        end
      end
    end
  end
end
