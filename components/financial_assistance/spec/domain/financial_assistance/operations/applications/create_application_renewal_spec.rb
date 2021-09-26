# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::CreateApplicationRenewal, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  before :all do
    DatabaseCleaner.clean
  end

  let!(:person) { FactoryBot.create(:person, :with_consumer_role, hbx_id: '100095')}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:application) do
    FactoryBot.create(:financial_assistance_application,
                      hbx_id: '111000222',
                      family_id: family.id,
                      is_renewal_authorized: false,
                      is_requesting_voter_registration_application_in_mail: true,
                      years_to_renew: 5,
                      medicaid_terms: true,
                      report_change_terms: true,
                      medicaid_insurance_collection_terms: true,
                      parent_living_out_of_home_terms: true,
                      attestation_terms: true,
                      submission_terms: true,
                      assistance_year: TimeKeeper.date_of_record.year,
                      full_medicaid_determination: true)
  end

  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      person_hbx_id: '100095',
                      is_primary_applicant: true,
                      family_member_id: family.primary_applicant.id,
                      first_name: 'Gerald',
                      last_name: 'Rivers',
                      dob: Date.new(Date.today.year - 22, Date.today.month, Date.today.day),
                      application: application)
  end

  let(:event) { Success(double) }
  let(:operation_instance) { described_class.new }

  before do
    allow(operation_instance.class).to receive(:new).and_return(operation_instance)
    allow(operation_instance).to receive(:build_event).and_return(event)
    allow(event.success).to receive(:publish).and_return(true)
  end

  context 'success' do
    context 'submitted application' do
      before do
        application.update_attributes!(aasm_state: 'submitted')
        application.reload
        @result = subject.call({ family_id: application.family_id, renewal_year: application.assistance_year.next })
        @renewal_draft_app = @result.success
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should return application' do
        expect(@renewal_draft_app).to be_a(::FinancialAssistance::Application)
      end

      it 'should return application in renewal_draft state' do
        expect(@renewal_draft_app.renewal_draft?).to be_truthy
      end

      it 'should return application with predecessor_id' do
        expect(@renewal_draft_app.predecessor_id).to eq(application.id)
      end

      it 'should return application with assistance_year' do
        expect(@renewal_draft_app.assistance_year).to eq(application.assistance_year.next)
      end

      it 'should return application with effective_date' do
        expect(@renewal_draft_app.effective_date).to eq(Date.new(application.assistance_year.next))
      end

      # Verify if all the answers for questions on 'Your Preferences' & 'Submit Your Application' were copied
      context 'for attestations & other questions' do
        # Your Preferences:
        #   is_renewal_authorized
        #   is_requesting_voter_registration_application_in_mail
        #   years_to_renew
        context 'Your Preferences' do
          it 'should return application with is_renewal_authorized' do
            expect(@renewal_draft_app.is_renewal_authorized).to eq(application.is_renewal_authorized)
          end

          it 'should return application with is_requesting_voter_registration_application_in_mail' do
            expect(@renewal_draft_app.is_requesting_voter_registration_application_in_mail).to eq(application.is_requesting_voter_registration_application_in_mail)
          end

          it 'should return application with years_to_renew one less than previous application' do
            expect(@renewal_draft_app.years_to_renew).to eq(application.years_to_renew.pred)
          end
        end

        # Submit Your Application:
        #   medicaid_terms
        #   report_change_terms
        #   medicaid_insurance_collection_terms
        #   parent_living_out_of_home_terms
        #   attestation_terms
        #   submission_terms
        #   full_medicaid_determination
        context 'Submit Your Application' do
          it 'should return application with medicaid_terms' do
            expect(@renewal_draft_app.medicaid_terms).to eq(application.medicaid_terms)
          end

          it 'should return application with report_change_terms' do
            expect(@renewal_draft_app.report_change_terms).to eq(application.report_change_terms)
          end

          it 'should return application with medicaid_insurance_collection_terms' do
            expect(@renewal_draft_app.medicaid_insurance_collection_terms).to eq(application.medicaid_insurance_collection_terms)
          end

          it 'should return application with parent_living_out_of_home_terms' do
            expect(@renewal_draft_app.parent_living_out_of_home_terms).to eq(application.parent_living_out_of_home_terms)
          end

          it 'should return application with submission_terms' do
            expect(@renewal_draft_app.submission_terms).to eq(application.submission_terms)
          end

          it 'should return application with attestation_terms' do
            expect(@renewal_draft_app.attestation_terms).to eq(application.attestation_terms)
          end

          it 'should return application with full_medicaid_determination' do
            expect(@renewal_draft_app.full_medicaid_determination).to eq(application.full_medicaid_determination)
          end
        end
      end
    end

    context 'determined application' do
      before do
        application.update_attributes!({ aasm_state: 'determined', years_to_renew: [0, nil].sample })
        application.reload
        @result = subject.call({ family_id: application.family_id, renewal_year: application.assistance_year.next })
        @renewal_draft_app = @result.success
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should return application' do
        expect(@renewal_draft_app).to be_a(::FinancialAssistance::Application)
      end

      it 'should return application in renewal_draft state' do
        expect(@renewal_draft_app.renewal_draft?).to be_truthy
      end

      it 'should return application with predecessor_id' do
        expect(@renewal_draft_app.predecessor_id).to eq(application.id)
      end

      it 'should return application with assistance_year' do
        expect(@renewal_draft_app.assistance_year).to eq(application.assistance_year.next)
      end

      # Verify if all the answers for questions on 'Your Preferences' & 'Submit Your Application' were copied
      context 'for attestations & other questions' do
        # Your Preferences:
        #   is_renewal_authorized
        #   is_requesting_voter_registration_application_in_mail
        #   years_to_renew
        context 'Your Preferences' do
          it 'should return application with is_renewal_authorized' do
            expect(@renewal_draft_app.is_renewal_authorized).to eq(application.is_renewal_authorized)
          end

          it 'should return application with is_requesting_voter_registration_application_in_mail' do
            expect(@renewal_draft_app.is_requesting_voter_registration_application_in_mail).to eq(application.is_requesting_voter_registration_application_in_mail)
          end

          it 'should return application with years_to_renew as zero' do
            expect(@renewal_draft_app.years_to_renew).to be_zero
          end
        end

        # Submit Your Application:
        #   medicaid_terms
        #   report_change_terms
        #   medicaid_insurance_collection_terms
        #   parent_living_out_of_home_terms
        #   attestation_terms
        #   submission_terms
        #   full_medicaid_determination
        context 'Submit Your Application' do
          it 'should return application with medicaid_terms' do
            expect(@renewal_draft_app.medicaid_terms).to eq(application.medicaid_terms)
          end

          it 'should return application with report_change_terms' do
            expect(@renewal_draft_app.report_change_terms).to eq(application.report_change_terms)
          end

          it 'should return application with medicaid_insurance_collection_terms' do
            expect(@renewal_draft_app.medicaid_insurance_collection_terms).to eq(application.medicaid_insurance_collection_terms)
          end

          it 'should return application with parent_living_out_of_home_terms' do
            expect(@renewal_draft_app.parent_living_out_of_home_terms).to eq(application.parent_living_out_of_home_terms)
          end

          it 'should return application with submission_terms' do
            expect(@renewal_draft_app.submission_terms).to eq(application.submission_terms)
          end

          it 'should return application with attestation_terms' do
            expect(@renewal_draft_app.attestation_terms).to eq(application.attestation_terms)
          end

          it 'should return application with full_medicaid_determination' do
            expect(@renewal_draft_app.full_medicaid_determination).to eq(application.full_medicaid_determination)
          end
        end
      end
    end

    context 'imported application' do
      before do
        application.update_attributes!({ aasm_state: 'imported', years_to_renew: [0, nil].sample })
        application.reload
        @result = subject.call({ family_id: application.family_id, renewal_year: application.assistance_year.next })
        @renewal_draft_app = @result.success
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should return application' do
        expect(@renewal_draft_app).to be_a(::FinancialAssistance::Application)
      end

      it 'should return application in renewal_draft state' do
        expect(@renewal_draft_app.renewal_draft?).to be_truthy
      end

      it 'should return application with predecessor_id' do
        expect(@renewal_draft_app.predecessor_id).to eq(application.id)
      end

      it 'should return application with assistance_year' do
        expect(@renewal_draft_app.assistance_year).to eq(application.assistance_year.next)
      end

      # Verify if all the answers for questions on 'Your Preferences' & 'Submit Your Application' were copied
      context 'for attestations & other questions' do
        # Your Preferences:
        #   is_renewal_authorized
        #   is_requesting_voter_registration_application_in_mail
        #   years_to_renew
        context 'Your Preferences' do
          it 'should return application with is_renewal_authorized' do
            expect(@renewal_draft_app.is_renewal_authorized).to eq(application.is_renewal_authorized)
          end

          it 'should return application with is_requesting_voter_registration_application_in_mail' do
            expect(@renewal_draft_app.is_requesting_voter_registration_application_in_mail).to eq(application.is_requesting_voter_registration_application_in_mail)
          end

          it 'should return application with years_to_renew as zero' do
            expect(@renewal_draft_app.years_to_renew).to be_zero
          end
        end

        # Submit Your Application:
        #   medicaid_terms
        #   report_change_terms
        #   medicaid_insurance_collection_terms
        #   parent_living_out_of_home_terms
        #   attestation_terms
        #   submission_terms
        #   full_medicaid_determination
        context 'Submit Your Application' do
          it 'should return application with medicaid_terms' do
            expect(@renewal_draft_app.medicaid_terms).to eq(application.medicaid_terms)
          end

          it 'should return application with report_change_terms' do
            expect(@renewal_draft_app.report_change_terms).to eq(application.report_change_terms)
          end

          it 'should return application with medicaid_insurance_collection_terms' do
            expect(@renewal_draft_app.medicaid_insurance_collection_terms).to eq(application.medicaid_insurance_collection_terms)
          end

          it 'should return application with parent_living_out_of_home_terms' do
            expect(@renewal_draft_app.parent_living_out_of_home_terms).to eq(application.parent_living_out_of_home_terms)
          end

          it 'should return application with submission_terms' do
            expect(@renewal_draft_app.submission_terms).to eq(application.submission_terms)
          end

          it 'should return application with attestation_terms' do
            expect(@renewal_draft_app.attestation_terms).to eq(application.attestation_terms)
          end

          it 'should return application with full_medicaid_determination' do
            expect(@renewal_draft_app.full_medicaid_determination).to eq(application.full_medicaid_determination)
          end
        end
      end
    end

    context 'renewal_base_year' do
      before do
        application.update_attributes!({ aasm_state: 'draft', years_to_renew: rand(0..5), is_renewal_authorized: false })
        application.submit!
        @result = subject.call({ family_id: application.family_id, renewal_year: application.assistance_year.next })
        @renewal_draft_app = @result.success
      end

      it 'should return renewal_base_year for renewal_draft_app same as input_application' do
        expect(@renewal_draft_app.renewal_base_year).to eq(application.renewal_base_year)
      end
    end
  end

  context 'failure' do
    context 'missing keys' do
      context 'missing family_id' do
        before do
          @result = subject.call({ renewal_year: TimeKeeper.date_of_record.year })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq('Missing family_id key')
        end
      end

      context 'missing renewal_year' do
        before do
          @result = subject.call({ family_id: BSON::ObjectId.new })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq('Missing renewal_year key')
        end
      end
    end

    context 'missing values or invalid values' do
      context 'missing value for family_id' do
        before do
          @result = subject.call({ family_id: nil, renewal_year: TimeKeeper.date_of_record.year })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq("Invalid value:  for key family_id, must be a valid object identifier")
        end
      end

      context 'missing value for renewal_year' do
        before do
          @result = subject.call({ family_id: family.id, renewal_year: nil })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq('Invalid value:  for key renewal_year, must be an Integer')
        end
      end

      context 'invalid value for family_id' do
        before do
          @result = subject.call({ family_id: 'test', renewal_year: TimeKeeper.date_of_record.year })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to match('Cannot find family with input value: test for key family_id')
        end
      end

      context 'invalid value for renewal_year' do
        before do
          @result = subject.call({ family_id: family.id, renewal_year: TimeKeeper.date_of_record.year.to_s })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to match(/for key renewal_year, must be an Integer/)
        end
      end
    end

    context 'no applications for given inputs' do
      let(:validated_params) { { family_id: family.id, renewal_year: TimeKeeper.date_of_record.year } }
      before do
        ::FinancialAssistance::Application.destroy_all
        @result = subject.call(validated_params)
      end

      it 'should return failure with error message' do
        expect(@result.failure).to eq("Could not find any applications that are renewal eligible: #{validated_params}.")
      end
    end

    context 'for an application which is not in determined state' do
      shared_examples_for 'non determined state application' do |app_state|

        let(:validated_params) { { family_id: application.family_id, renewal_year: application.assistance_year.next } }
        before do
          application.update_attributes!(aasm_state: app_state)
          @result = subject.call(validated_params)
        end

        it 'should return failure' do
          expect(@result).to be_failure
        end

        it "should return failure with error messasge for application with aasm_state: #{app_state}" do
          expect(@result.failure).to eq("Could not find any applications that are renewal eligible: #{validated_params}.")
        end
      end

      context 'failure because of application aasm_state' do
        it_behaves_like 'non determined state application', 'draft'
        it_behaves_like 'non determined state application', 'renewal_draft'
        it_behaves_like 'non determined state application', 'determination_response_error'
      end
    end
  end
end
