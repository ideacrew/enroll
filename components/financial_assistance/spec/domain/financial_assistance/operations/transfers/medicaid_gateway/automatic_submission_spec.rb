# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Transfers::MedicaidGateway::AutomaticSubmission, dbclean: :after_each do
  include Dry::Monads[:do, :result]

  let!(:person) { FactoryBot.create(:person, :with_ssn)}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id, aasm_state: 'draft', effective_date: TimeKeeper.date_of_record.beginning_of_year) }
  let(:request_operation) { instance_double('FinancialAssistance::Operations::Applications::MedicaidGateway::RequestEligibilityDetermination') }
  let(:result) { subject.call(application) }

  before do
    allow(FinancialAssistance::Operations::Applications::MedicaidGateway::RequestEligibilityDetermination).to receive(:new).and_return(request_operation)
    allow(request_operation).to receive(:call).and_return(Success(double))
  end

  it 'should return success' do
    expect(result).to be_success
  end

  it 'should call request eligibility determination operation' do
    result
    expect(request_operation).to have_received(:call)
  end
end