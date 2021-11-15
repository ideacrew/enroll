# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::Haven::RequestMagiMedicaidEligibilityDetermination, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  before do
    allow_any_instance_of(FinancialAssistance::Income).to receive(:skip_zero_income_amount_validation).and_return true
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
    appli
  end
  let!(:create_appli) do
    appli = FactoryBot.build(:financial_assistance_applicant,
                             person_hbx_id: '100095',
                             is_primary_applicant: true,
                             first_name: 'Gerald',
                             last_name: 'Rivers',
                             citizen_status: 'us_citizen',
                             family_member_id: family.primary_applicant.id,
                             gender: 'male',
                             ethnicity: [],
                             dob: Date.new(Date.today.year - 22, Date.today.month, Date.today.day))
    appli.addresses = [FactoryBot.build(:financial_assistance_address,
                                        :address_1 => '1111 Awesome Street NE',
                                        :address_2 => '#111',
                                        :address_3 => '',
                                        :city => 'Washington',
                                        :country_name => '',
                                        :kind => 'home',
                                        :state => FinancialAssistanceRegistry[:enroll_app].setting(:state_abbreviation).item,
                                        :zip => '20001',
                                        county: '')]
    application10.applicants.destroy_all
    application10.applicants = [appli]
    application10.save!
    application10.submit!
    appli
  end

  let(:event) { Success(double) }
  let(:obj) { ::FinancialAssistance::Operations::Applications::MedicaidGateway::PublishApplication.new }
  let(:obj2) { ::FinancialAssistance::Operations::Applications::CreateApplicationRenewal.new }

  before do
    allow(obj.class).to receive(:new).and_return(obj)
    allow(obj).to receive(:build_event).and_return(event)
    allow(obj2.class).to receive(:new).and_return(obj2)
    allow(obj2).to receive(:build_event).and_return(event)
    allow(event.success).to receive(:publish).and_return(true)
  end

  context 'success' do
    context 'is_renewal_authorized set to true i.e. renewal authorized for next 5 years' do
      before do
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:haven_determination).and_return(true)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:verification_type_income_verification).and_return(true)
        @renewal_draft = ::FinancialAssistance::Operations::Applications::CreateApplicationRenewal.new.call(
          { family_id: application10.family_id, renewal_year: application10.assistance_year.next }
        ).success
        @result = subject.call(@renewal_draft.serializable_hash.deep_symbolize_keys)
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
        @renewal_draft = ::FinancialAssistance::Operations::Applications::CreateApplicationRenewal.new.call(
          { family_id: application10.family_id, renewal_year: application10.assistance_year.next }
        ).success
        @result = subject.call(@renewal_draft.serializable_hash.deep_symbolize_keys)
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

    # Predecessor Application:
    #   assistance_year: 2021
    #   renewal_base_year: 2022
    context "predecessor_application’s renewal_base_year equals to renewal_application’s assistance_year" do
      before do
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:haven_determination).and_return(true)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:verification_type_income_verification).and_return(true)
        application10.update_attributes!({ is_renewal_authorized: false, years_to_renew: 1, renewal_base_year: nil })
        application10.set_renewal_base_year
        @renewal_draft = ::FinancialAssistance::Operations::Applications::CreateApplicationRenewal.new.call(
          { family_id: application10.family_id, renewal_year: application10.assistance_year.next }
        ).success
        @result = subject.call(@renewal_draft.serializable_hash.deep_symbolize_keys)
        @renewed_app = @result.success
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should return renewal application with renewal_base_year same as assistance_year' do
        expect(@renewed_app.renewal_base_year).to eq(@renewed_app.assistance_year)
        expect(@renewed_app.renewal_base_year).to eq(application10.assistance_year + application10.years_to_renew)
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
    before do
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:haven_determination).and_return(true)
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:verification_type_income_verification).and_return(true)
    end

    context 'invalid input data' do
      before do
        @result = subject.call('test')
      end

      it 'should return failure with error message' do
        expect(@result.failure).to eq('Input params is not a hash: test')
      end
    end

    context 'ineligible application' do
      before do
        @renewal_draft = ::FinancialAssistance::Operations::Applications::CreateApplicationRenewal.new.call(
          { family_id: application10.family_id, renewal_year: application10.assistance_year.next }
        ).success
      end

      context 'expired permission for renewal' do
        before do
          @renewal_draft.update_attributes!(renewal_base_year: @renewal_draft.assistance_year.pred)
          @result = subject.call(@renewal_draft.serializable_hash.deep_symbolize_keys)
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq("Expired Submission is failed for hbx_id: #{@renewal_draft.hbx_id}")
        end

        it 'should transition application to income_verification_extension_required state' do
          expect(@renewal_draft.reload.income_verification_extension_required?).to be_truthy
        end
      end
    end

    context 'Haven request failure because of invalid payload' do
      let!(:create_job_income) do
        inc = ::FinancialAssistance::Income.new({
                                                  kind: 'wages_and_salaries',
                                                  frequency_kind: 'yearly',
                                                  amount: 30_000.00,
                                                  start_on: TimeKeeper.date_of_record.beginning_of_month,
                                                  employer_name: 'Testing employer'
                                                })
        create_appli.incomes = [inc]
        create_appli.save!
      end

      before :each do
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:haven_determination).and_return(true)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:verification_type_income_verification).and_return(true)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:skip_zero_income_amount_validation).and_return(true)
        @renewal_app = ::FinancialAssistance::Operations::Applications::CreateApplicationRenewal.new.call(
          { family_id: application10.family_id, renewal_year: application10.assistance_year.next }
        ).success
        income = @renewal_app.applicants.first.incomes.first
        income.assign_attributes(kind: 'test')
        income.save(validate: false)
        @result = subject.call(@renewal_app.serializable_hash.deep_symbolize_keys)
      end

      it 'should return failure' do
        expect(@result).to be_failure
      end

      it 'should transition the application to magi_medicaid_eligibility_request_errored' do
        expect(@renewal_app.reload.haven_magi_medicaid_eligibility_request_errored?).to be_truthy
      end

      it 'should return failure with a message' do
        expect(@result.failure).to include(/The value 'urn:openhbx:terms:v1:financial_assistance_income#test' is not an element of the set {'ur/)
      end
    end
  end
end
