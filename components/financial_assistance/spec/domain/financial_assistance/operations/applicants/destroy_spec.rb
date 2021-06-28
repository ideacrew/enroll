# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Operations::Applicants::Destroy, dbclean: :after_each do

  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: BSON::ObjectId.new, aasm_state: 'draft') }
  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      application: application,
                      is_primary_applicant: true,
                      family_member_id: BSON::ObjectId.new,
                      person_hbx_id: '1000',
                      ssn: '889984400',
                      dob: Date.new(1993,12,9),
                      first_name: 'james',
                      last_name: 'bond')
  end
  let!(:applicant2) do
    FactoryBot.create(:financial_assistance_applicant,
                      application: application,
                      is_primary_applicant: false,
                      family_member_id: BSON::ObjectId.new,
                      person_hbx_id: '1001',
                      ssn: '889984401',
                      dob: Date.new(2000, 12, 9),
                      first_name: 'child',
                      last_name: 'bond')
  end

  before do
    @result = subject.call(input_params)
  end

  context 'for failures' do
    context 'invalid input' do
      let(:input_params) { 'test' }

      it 'should return a failure' do
        expect(@result.failure).to eq("Given input: #{input_params} is not a valid FinancialAssistance::Applicant.")
      end
    end

    context 'applicant is primary' do
      let(:input_params) { applicant }

      it 'should return a failure' do
        expect(@result.failure).to eq("Given applicant with person_hbx_id: #{applicant.person_hbx_id} is a primary applicant, cannot be destroyed/deleted.")
      end
    end

    context 'application is not draft' do
      let(:input_params) do
        application.update_attributes!(aasm_state: 'submitted')
        applicant2
      end

      it 'should return a failure' do
        expect(@result.failure).to eq("The application with hbx_id: #{application.hbx_id} for given applicant with person_hbx_id: #{applicant2.person_hbx_id} is not a draft application, applicant cannot be destroyed/deleted.")
      end
    end
  end

  context 'success' do
    context 'no relationships' do
      let(:input_params) { applicant2 }

      it 'should return success' do
        expect(@result.success).to eq('Successfully destroyed applicant with person_hbx_id: 1001.')
      end

      it 'should return only one applicant' do
        expect(application.applicants.count).to eq(1)
      end

      it 'should destroy applicant' do
        expect(application.applicants.where(person_hbx_id: '1001').first).to be_nil
      end
    end

    context 'with relationships' do
      let(:input_params) do
        application.ensure_relationship_with_primary(applicant2, 'spouse')
        applicant2
      end

      it 'should return success' do
        expect(@result.success).to eq('Successfully destroyed applicant with person_hbx_id: 1001.')
      end

      it 'should return only one applicant' do
        expect(application.applicants.count).to eq(1)
      end

      it 'should destroy applicant' do
        expect(application.applicants.where(person_hbx_id: '1001').first).to be_nil
      end

      it 'should destroy relationships' do
        expect(application.relationships.count).to be_zero
      end
    end
  end
end
