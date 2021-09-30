# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::Haven::AddEligibilityDetermination, dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  let(:message) do
    {determination_http_status_code: 200, has_eligibility_response: true,
     haven_app_id: '1234', haven_ic_id: '124', eligibility_response_payload: xml}
  end
  let!(:person) do
    FactoryBot.create(:person, :with_consumer_role, hbx_id: '20944967', last_name: 'Test', first_name: 'Domtest34', ssn: '243108282', dob: Date.new(1984, 3, 8))
  end

  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:family_id) { family.id }
  let(:family_member_id) { BSON::ObjectId.new }
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family_id, hbx_id: '5979ec3cd7c2dc47ce000000', aasm_state: 'submitted') }
  let!(:ed) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application, csr_percent_as_integer: nil, max_aptc: 0.0) }
  let!(:applicant) do
    FactoryBot.create(:applicant, application: application,
                                  family_member_id: family_member_id,
                                  person_hbx_id: person.hbx_id,
                                  ssn: '243108282',
                                  dob: Date.new(1984, 3, 8),
                                  first_name: 'Domtest34',
                                  last_name: 'Test',
                                  eligibility_determination_id: ed.id)
  end


  context 'success' do
    context 'Haven Integration payload' do
      let(:xml) { File.read(::FinancialAssistance::Engine.root.join('spec', 'test_data', 'haven_eligibility_response_payloads', 'verified_1_member_family.xml')) }

      before do
        ed.update_attributes!(hbx_assigned_id: '205828')
        application.update_response_attributes(message)
        @result = subject.call(application: application)
        @ed = ed
        @applicant = @ed.applicants.first
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should return true' do
        expect(@result.success).to eq(true)
      end


      context 'for Eligibility Determination' do
        it 'should update max_aptc' do
          expect(@ed.max_aptc.to_f).to eq(47.78)
        end

        it 'should update is_eligibility_determined' do
          expect(@ed.is_eligibility_determined).to eq(true)
        end

        it 'should update source' do
          expect(@ed.source).to eq('Faa')
        end
      end

      context 'for Applicant' do
        it 'should update is_ia_eligible' do
          expect(@applicant.is_ia_eligible).to eq(true)
        end

        it 'should update is_medicaid_chip_eligible' do
          expect(@applicant.is_medicaid_chip_eligible).to eq(false)
        end

        it 'should update csr percentage as integer' do
          expect(@applicant.csr_eligibility_kind).to eq("csr_100")
        end
      end
    end

    context 'xml without eligibility_determinations section' do
      let(:xml) { File.read(::FinancialAssistance::Engine.root.join('spec', 'test_data', 'haven_eligibility_response_payloads', 'verified_1_member_family_without_ed.xml')) }

      before do
        ed.update_attributes!(hbx_assigned_id: '205828')
        application.update_response_attributes(message)
        @result = subject.call(application: application)
        @ed = ed
        @applicant = @ed.applicants.first
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should return true' do
        expect(@result.success).to eq(true)
      end

      context 'for Eligibility Determination' do
        it 'should update determined_at' do
          expect(@ed.determined_at).not_to be_nil
          expect(@ed.determined_at).to be_truthy
        end

        it 'should update source' do
          expect(@ed.source).to eq('Faa')
        end
      end

      context 'for Applicant' do
        it 'should update is_without_assistance' do
          expect(@applicant.is_without_assistance).to eq(true)
        end

        it 'should update is_ia_eligible' do
          expect(@applicant.is_ia_eligible).to eq(false)
        end

        it 'should update is_medicaid_chip_eligible' do
          expect(@applicant.is_medicaid_chip_eligible).to eq(false)
        end

        it 'should set csr_eligibility_kind to default' do
          expect(@applicant.csr_eligibility_kind).to eq('csr_0')
        end
      end
    end

  end

  context 'failure' do
    context 'invalid response payload' do
      before do
        @result = subject.call({ test: 'test' })
      end

      it 'should return failure' do
        expect(@result).to be_failure
      end
    end

    context 'no response payload present on application' do

      before do
        @result = subject.call(application: application)
      end

      it 'should return failure' do
        expect(@result).to be_failure
      end

      it 'should return failure with error message' do
        expect(@result.failure).to eq('No response payload')
      end
    end
  end
end
