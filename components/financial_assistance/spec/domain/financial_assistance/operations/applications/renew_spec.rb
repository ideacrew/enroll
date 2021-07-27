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
    FactoryBot.create(:financial_assistance_application, hbx_id: '111000222', family_id: family.id, assistance_year: TimeKeeper.date_of_record.year)
  end
  let!(:create_appli) do
    appli = FactoryBot.build(:financial_assistance_applicant,
                             :with_work_phone,
                             person_hbx_id: '100095',
                             is_primary_applicant: true,
                             first_name: 'Gerald',
                             last_name: 'Rivers',
                             family_member_id: family.primary_applicant.id,
                             gender: 'Male',
                             ethnicity: [],
                             dob: Date.new(Date.today.year - 22, Date.today.month, Date.today.day))
    appli.phones = [FactoryBot.build(:financial_assistance_phone,
                                     kind: 'work',
                                     area_code: '202',
                                     number: '1111111',
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
    before do
      @renewal_draft = ::FinancialAssistance::Operations::Applications::CreateRenewalDraft.new.call(
        { family_id: application10.family_id, renewal_year: application10.assistance_year.next }
      ).success
      @result = subject.call(@renewal_draft)
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

  context 'failure' do
    context 'invalid input data' do
      before do
        @result = subject.call('test')
      end

      it 'should return failure with error message' do
        expect(@result.failure).to eq("Given input: test is not a valid FinancialAssistance::Application.")
      end
    end

    context 'for an application which is not in renewal_draft state' do
      shared_examples_for 'non renewal_draft state application' do |app_state|
        before do
          application10.update_attributes!(aasm_state: app_state)
          @result = subject.call(application10)
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

    context 'incomplete application' do
      before do
        @renewal_draft = ::FinancialAssistance::Operations::Applications::CreateRenewalDraft.new.call(
          { family_id: application10.family_id, renewal_year: application10.assistance_year.next }
        ).success
        allow(@renewal_draft).to receive(:complete?).and_return(false)
        @result = subject.call(@renewal_draft)
      end

      it 'should return failure with error message' do
        expect(@result.failure).to eq("Given application with hbx_id: #{@renewal_draft.hbx_id} is not valid for submission")
      end
    end
  end
end
