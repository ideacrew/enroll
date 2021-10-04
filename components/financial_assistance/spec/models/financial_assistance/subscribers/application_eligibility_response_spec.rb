# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Subscribers::ApplicationEligibilityResponse, type: :model, dbclean: :after_each do

  let(:xml) { File.read(::FinancialAssistance::Engine.root.join('spec', 'test_data', 'haven_eligibility_response_payloads', 'verified_1_member_family.xml')) }
  let(:payload) do
    {
      assistance_application_id: "5979ec3cd7c2dc47ce000000",
      body: xml,
      return_status: 203
    }
  end

  let!(:person) do
    FactoryBot.create(:person, :with_consumer_role, hbx_id: '20944967', last_name: 'Test', first_name: "O'Keefe", ssn: '243108282', dob: Date.new(1984, 3, 8))
  end

  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:family_member10_id) { BSON::ObjectId.new }
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id, hbx_id: '5979ec3cd7c2dc47ce000000', aasm_state: 'submitted') }
  let!(:ed) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application, csr_percent_as_integer: nil, max_aptc: 0.0) }
  let!(:applicant) do
    FactoryBot.create(:applicant, application: application,
                      family_member_id: family_member10_id,
                      person_hbx_id: person.hbx_id,
                      ssn: '243108282',
                      dob: Date.new(1984, 3, 8),
                      first_name: 'Domtest34',
                      last_name: 'Test',
                      eligibility_determination_id: ed.id)
  end

  let!(:eligibility_determination) { FactoryBot.create(:financial_assistance_eligibility_determination, hbx_assigned_id: "205828", application: application) }


  before do
    eligibility_determination.update!(hbx_assigned_id: "205828")
    subject.call("_event_name", "_e_start", "_e_end", "_msg_id", payload)
  end

  it "should transition application to determined state" do
    expect(application.reload.aasm_state).to eq 'determined'
  end
end