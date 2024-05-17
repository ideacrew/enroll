# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::ProcessDateChangeEvents, dbclean: :after_each do
  include Dry::Monads[:do, :result]

  before :all do
    DatabaseCleaner.clean
    logger_name = "#{Rails.root}/log/fa_application_advance_day_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
    File.delete(logger_name) if File.exist?(logger_name)
  end

  after :all do
    logger_name = "#{Rails.root}/log/fa_application_advance_day_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
    File.delete(logger_name) if File.exist?(logger_name)
  end

  let(:current_date) { TimeKeeper.date_of_record }
  let(:current_year) { current_date.year }
  let(:renewal_year) { current_year.next }

  let!(:person) { FactoryBot.create(:person, hbx_id: "732020") }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
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
                      aasm_state: 'determined',
                      submission_terms: true,
                      assistance_year: current_year,
                      full_medicaid_determination: true)
  end

  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      person_hbx_id: '100095',
                      is_primary_applicant: true,
                      first_name: 'Gerald',
                      last_name: 'Rivers',
                      dob: Date.new(Date.today.year - 22, Date.today.month, Date.today.beginning_of_month.day),
                      application: application)
  end

  let!(:enrollment) do
    FactoryBot.create(:hbx_enrollment, family: family,
                                       kind: "individual",
                                       coverage_kind: "health",
                                       product_id: BSON::ObjectId.new,
                                       aasm_state: 'coverage_selected',
                                       effective_on: current_date.beginning_of_year,
                                       hbx_enrollment_members: [
                                         FactoryBot.build(:hbx_enrollment_member,
                                                          applicant_id: family.primary_applicant.id,
                                                          eligibility_date: current_date.beginning_of_year,
                                                          coverage_start_on: current_date.beginning_of_year,
                                                          is_subscriber: true)
                                       ])
  end

  let(:logger_file_name) { "#{Rails.root}/log/fa_application_advance_day_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log" }
  let(:logger) { Logger.new(logger_file_name) }
  let(:event) { Success(double) }
  let(:obj)  { ::FinancialAssistance::Operations::Applications::MedicaidGateway::PublishApplication.new }

  let(:renewal_draft_application) do
    FactoryBot.create(:financial_assistance_application,
                      hbx_id: '111000223',
                      family_id: family.id,
                      is_renewal_authorized: false,
                      is_requesting_voter_registration_application_in_mail: true,
                      years_to_renew: 5,
                      medicaid_terms: true,
                      report_change_terms: true,
                      medicaid_insurance_collection_terms: true,
                      parent_living_out_of_home_terms: true,
                      attestation_terms: true,
                      aasm_state: 'renewal_draft',
                      submission_terms: true,
                      assistance_year: renewal_year,
                      full_medicaid_determination: true)
  end

  before do
    allow(::FinancialAssistance::Operations::Applications::MedicaidGateway::PublishApplication).to receive(:new).and_return(obj)
    allow(obj).to receive(:build_event).and_return(event)
    allow(event.success).to receive(:publish).and_return(true)
  end

  context 'success' do
    let(:input_params) do
      { events_execution_date: TimeKeeper.date_of_record, logger: logger, renewal_year: renewal_year }
    end

    context 'without renewal draft application' do
      before { @result = subject.call(input_params) }

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should return success with message' do
        expect(@result.success).to eq('Successfully processed all the date change events.')
      end

      it 'should not log any error in the logger file' do
        expect(File.read(logger_file_name)).not_to include('error')
      end
    end

    context 'with renewal draft application' do
      before do
        renewal_draft_application
        @result = subject.call(input_params)
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should return success with message' do
        expect(@result.success).to eq('Successfully processed all the date change events.')
      end

      it 'should not log any error in the logger file' do
        expect(File.read(logger_file_name)).not_to include('error')
      end
    end
  end

  context 'failure' do
    before { @result = subject.call(input_params) }

    context 'missing keys' do
      context 'missing events_execution_date' do
        let(:input_params) do
          { logger: logger, renewal_year: renewal_year }
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq('Missing events_execution_date key')
        end
      end

      context 'missing logger' do
        let(:input_params) do
          { events_execution_date: TimeKeeper.date_of_record, renewal_year: renewal_year }
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq('Missing logger key')
        end
      end

      context 'missing renewal_year' do
        let(:input_params) do
          { events_execution_date: TimeKeeper.date_of_record, logger: logger }
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq('Missing renewal_year key')
        end
      end
    end

    context 'missing values or invalid values' do
      context 'missing value for events_execution_date' do
        let(:input_params) do
          { events_execution_date: nil, logger: logger, renewal_year: renewal_year }
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq('Invalid value:  for key events_execution_date, must be a Date object')
        end
      end

      context 'missing value for logger' do
        let(:input_params) do
          { events_execution_date: TimeKeeper.date_of_record, logger: nil, renewal_year: renewal_year }
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq('Invalid value:  for key logger, must be a Logger object')
        end
      end

      context 'invalid value for renewal_year' do
        let(:input_params) do
          { events_execution_date: TimeKeeper.date_of_record, logger: logger, renewal_year: nil }
        end

        it 'should return failure with error message' do
          expect(@result.failure).to match(/for key renewal_year, must be an Integer/)
        end
      end
    end
  end
end
