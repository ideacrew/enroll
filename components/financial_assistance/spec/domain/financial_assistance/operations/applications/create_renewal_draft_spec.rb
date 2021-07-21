# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::CreateRenewalDraft, dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  let!(:application) do
    FactoryBot.create(:financial_assistance_application, hbx_id: '111000222')
  end

  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      person_hbx_id: '100095',
                      is_primary_applicant: true,
                      first_name: 'Gerald',
                      last_name: 'Rivers',
                      dob: Date.new(Date.today.year - 22, Date.today.month, Date.today.day),
                      application: application)
  end

  context 'success' do
    before do
      @result = subject.call(application)
      @renewal_draft_app = @result.success
    end

    it 'should return success' do
      expect(@result).to be_success
    end

    it 'should return application' do
      expect(@renewal_draft_app).to be_a(::FinancialAssistance::Application)
    end

    it 'should return application with renewal_draft' do
      expect(@renewal_draft_app.renewal_draft?).to be_truthy
    end

    it 'should return application with assistance_year' do
      expect(@renewal_draft_app.assistance_year).to eq(application.assistance_year.next)
    end
  end

  context 'failure' do
    context 'invalid input data' do
      before do
        @result = subject.call('test')
      end

      it 'should return failure with error message' do
        expect(@result.failure).to eq("Given input: test is not a valid FinancialAssistance::Application.")
      end
    end

    context 'for an application which is not in determined state' do
      shared_examples_for 'non determined state application' do |app_state|
        before do
          application.update_attributes!(aasm_state: app_state)
          @result = subject.call(application)
        end

        it 'should return failure' do
          expect(@result).to be_failure
        end

        it "should return failure with error messasge for application with aasm_state: #{app_state}" do
          expect(@result.failure).to eq("Cannot generate renewal_draft for given application with aasm_state #{application.aasm_state}. Application must be in determined state.")
        end
      end

      context 'failure because of application aasm_state' do
        it_behaves_like 'non determined state application', 'draft'
        it_behaves_like 'non determined state application', 'renewal_draft'
        it_behaves_like 'non determined state application', 'submitted'
        it_behaves_like 'non determined state application', 'determination_response_error'
      end
    end
  end
end
