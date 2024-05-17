# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::RetryEvidences, dbclean: :after_each do
  include Dry::Monads[:do, :result]

  before :all do
    DatabaseCleaner.clean
  end

  let!(:person) { FactoryBot.create(:person, :with_consumer_role, hbx_id: '100095')}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:application) do
    FactoryBot.create(:application,
                      family_id: family.id,
                      aasm_state: "determined",
                      effective_date: TimeKeeper.date_of_record)
  end

  let!(:applicant) do
    FactoryBot.create(:applicant,
                      application: application,
                      dob: TimeKeeper.date_of_record - 40.years,
                      is_primary_applicant: true,
                      family_member_id: family.family_members[0].id,
                      person_hbx_id: person.hbx_id,
                      addresses: [FactoryBot.build(:financial_assistance_address)])
  end

  let!(:income_evidence) do
    application.applicants.first.create_income_evidence(key: :income,
                                                        title: 'Income',
                                                        aasm_state: 'pending',
                                                        due_on: TimeKeeper.date_of_record,
                                                        verification_outstanding: true,
                                                        is_satisfied: false)
  end

  let!(:test_params) do
    {
      evidence_type: :income,
      applicants: [applicant],
      update_reason: "For testing purposes"
    }
  end

  context 'success' do
    context 'with valid params submitted and cv3 valid application' do
      before do
        allow(::Operations::Fdsh::RequestEvidenceDetermination).to receive_message_chain('new.call').with(income_evidence).and_return(Dry::Monads::Result::Success.new(application))

        @result = subject.call(test_params)
        applicant.reload
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should add a verification history recording the update for' do
        history = income_evidence.verification_histories.last
        expect(history.action).to eq("retry")
        expect(history.update_reason).to eq(test_params[:update_reason])
        expect(history.updated_by).to eq("system")
      end
    end

    context 'with cv3 invalid application' do
      before do
        allow(EnrollRegistry).to receive(:feature_enabled?).and_return(false)
        allow(EnrollRegistry).to receive(:feature_enabled?).with(:validate_and_record_publish_application_errors).and_return(true)

        allow(::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application).to receive_message_chain('new.call').with(application).and_return(Dry::Monads::Result::Failure.new(application))
        @result = subject.call(test_params)
        applicant.reload
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should add a verification history recording the retry failure' do
        first_history = applicant.income_evidence.verification_histories.first
        last_history = applicant.income_evidence.verification_histories.last

        # This test had to be slightly altered due to the new way of handling evidence histories
        # We want to record both the attempt at the determination, as well as the failure if it fails
        expect(first_history.action).to eq("retry")
        expect(first_history.update_reason).to include(test_params[:update_reason])
        expect(first_history.updated_by).to eq("system")

        expect(last_history.action).to eq("Hub Request Failed")
        expect(last_history.update_reason).to include("Evidence Determination Request Failed")
        expect(last_history.updated_by).to eq("system")
      end
    end
  end

  context 'failure' do
    context 'with invalid evidence_type' do
      it 'should fail if not a symbol' do
        test_params[:evidence_type] = "08/08/2023"
        result = subject.call(test_params)
        expect(result).to be_failure
        expect(result.failure).to eq("Missing or invalid param for key evidence_type, must be a valid evidence_type")
      end

      it 'should fail if missing' do
        test_params.delete(:evidence_type)
        result = subject.call(test_params)
        expect(result).to be_failure
        expect(result.failure).to eq("Missing or invalid param for key evidence_type, must be a valid evidence_type")
      end
    end

    context 'with invalid applicants' do
      it 'should fail if not an array' do
        test_params[:applicants] = "08/08/2023"
        result = subject.call(test_params)
        expect(result).to be_failure
        expect(result.failure).to eq("Missing or invalid param for key applicants, must be an array of applicants")
      end

      it 'should fail if missing' do
        test_params.delete(:applicants)
        result = subject.call(test_params)
        expect(result).to be_failure
        expect(result.failure).to eq("Missing or invalid param for key applicants, must be an array of applicants")
      end
    end

    context 'with invalid modified_by' do
      it 'should fail if not a string' do
        test_params[:modified_by] = Date.today
        result = subject.call(test_params)
        expect(result).to be_failure
        expect(result.failure).to eq("Invalid param for key modified_by, must be a String")
      end
    end

    context 'with invalid update_reason' do
      it 'should fail if not a string' do
        test_params[:update_reason] = Date.today
        result = subject.call(test_params)
        expect(result).to be_failure
        expect(result.failure).to eq("Missing or invalid param for key update_reason, must be a String")
      end

      it 'should fail if missing' do
        test_params.delete(:update_reason)
        result = subject.call(test_params)
        expect(result).to be_failure
        expect(result.failure).to eq("Missing or invalid param for key update_reason, must be a String")
      end
    end
  end
end