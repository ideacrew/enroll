# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::MedicaidGateway::PublishApplication, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  let!(:person) { FactoryBot.create(:person, hbx_id: "732020") }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id, aasm_state: 'submitted', hbx_id: "830293", effective_date: DateTime.new(2021,1,1,4,5,6)) }
  let!(:applicant) do
    applicant = FactoryBot.create(:applicant,
                                  first_name: person.first_name,
                                  last_name: person.last_name,
                                  dob: person.dob,
                                  gender: person.gender,
                                  ssn: person.ssn,
                                  application: application,
                                  person_hbx_id: person.hbx_id,
                                  ethnicity: [],
                                  is_primary_applicant: true,
                                  is_self_attested_blind: false,
                                  is_applying_coverage: true,
                                  is_required_to_file_taxes: true,
                                  is_pregnant: false,
                                  has_job_income: false,
                                  has_self_employment_income: false,
                                  has_unemployment_income: false,
                                  has_other_income: false,
                                  has_deductions: false,
                                  has_enrolled_health_coverage: false,
                                  has_eligible_health_coverage: false,
                                  has_eligible_medicaid_cubcare: false,
                                  is_claimed_as_tax_dependent: false,
                                  is_incarcerated: false,
                                  is_post_partum_period: false)
    applicant
  end

  let!(:eligibility_determination) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }
  let(:event) { Success(double) }
  let(:obj)  { FinancialAssistance::Operations::Applications::MedicaidGateway::PublishApplication.new }
  let!(:create_home_address) do
    application.applicants.first.update_attributes!(is_primary_applicant: true)
    add = ::FinancialAssistance::Locations::Address.new({
                                                          kind: 'home',
                                                          address_1: '3 Awesome Street',
                                                          address_2: '#300',
                                                          city: 'Washington',
                                                          state: 'DC',
                                                          zip: '20001'
                                                        })
    primary_appli = application.reload.primary_applicant
    primary_appli.addresses << add
    primary_appli.save!
  end

  let(:premiums_hash) do
    {
      [person.hbx_id] => {:health_only => {person.hbx_id => [{:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}]}}
    }
  end

  let(:slcsp_info) do
    {
      person.hbx_id => {:health_only_slcsp_premiums => {:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}}
    }
  end

  let(:lcsp_info) do
    {
      person.hbx_id => {:health_only_lcsp_premiums => {:cost => 100.0, :member_identifier => person.hbx_id, :monthly_premium => 100.0}}
    }
  end

  let(:fetch_double) { double(:new => double(call: double(:value! => premiums_hash)))}
  let(:fetch_slcsp_double) { double(:new => double(call: double(:value! => slcsp_info)))}
  let(:fetch_lcsp_double) { double(:new => double(call: double(:value! => lcsp_info)))}

  before do
    stub_const('::Operations::Products::Fetch', fetch_double)
    stub_const('::Operations::Products::FetchSlcsp', fetch_slcsp_double)
    stub_const('::Operations::Products::FetchLcsp', fetch_lcsp_double)
    allow(FinancialAssistance::Operations::Applications::MedicaidGateway::PublishApplication).to receive(:new).and_return(obj)
    allow(obj).to receive(:build_event).and_return(event)
    allow(event.success).to receive(:publish).and_return(true)
  end

  context 'When connection is available' do
    before do
      application_params = ::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application.reload)
      @result = subject.call({ payload: application_params.success, event_name: 'determine_eligibility' })
    end

    it 'should return success' do
      application_params = ::FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application.reload)
      expect(subject.call(application_params.success)).to be_success
    end
  end

  context 'failure' do
    context 'missing keys' do
      context 'missing payload' do
        before do
          @result = subject.call({ event_name: 'determine_eligibility' })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq('Missing payload key')
        end
      end

      context 'missing event_name' do
        before do
          @result = subject.call({ payload: { test: 'test' } })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq('Missing event_name key')
        end
      end
    end

    context 'missing values or invalid values' do
      context 'missing value for payload' do
        before do
          @result = subject.call({ payload: nil, event_name: 'determine_eligibility' })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq("Invalid value:  for key payload, must be a Hash object")
        end
      end

      context 'missing value for event_name' do
        before do
          @result = subject.call({ payload: { test: 'test' }, event_name: nil })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq("Invalid value:  for key event_name, must be an String")
        end
      end

      context 'invalid value for payload' do
        before do
          @result = subject.call({ payload: { test: 'test' }.to_s, event_name: 'determine_eligibility' })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to match(/for key payload, must be a Hash object/)
        end
      end

      context 'invalid value for event_name' do
        before do
          @result = subject.call({ payload: { test: 'test' }, event_name: :determine_eligibility })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to match(/for key event_name, must be an String/)
        end
      end

      context 'invalid value for event_name' do
        before do
          @result = subject.call({ payload: { test: 'test' }, event_name: 'test_event' })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq("Invalid event_name: test_event for key event_name, must be one of [\"determine_eligibility\", \"generate_renewal_draft\"]")
        end
      end
    end
  end
end
