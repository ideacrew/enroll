# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::MedicaidGateway::AddMecCheckPerson, dbclean: :after_each do
  include Dry::Monads[:do, :result]

  let(:person_id) { "b3dc8e08e28e487f80285fb79681b337" }

  let(:payload) do
    {
      application_identifier: "n/a",
      family_identifier: "10453",
      applicant_responses: { person_id => "Applicant Not Found" },
      type: "person"
    }
  end

  let(:invalid_payload) do
    {
      application_identifier: "n/a",
      family_identifier: "10453",
      applicant_responses: {}
    }
  end

  let!(:person) { FactoryBot.create(:person, hbx_id: "b3dc8e08e28e487f80285fb79681b337") }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }

  let(:operation) { ::FinancialAssistance::Operations::Applications::MedicaidGateway::AddMecCheckPerson.new }

  context 'Given an invalid payload' do
    it 'should fail' do
      result = operation.call(invalid_payload)
      expect(result).not_to be_success
    end
  end

  context 'Given a valid payload' do

    before :each do
      @result = operation.call(payload)
    end

    it 'should be successful' do
      expect(@result).to be_success
    end

    it 'should update the Person MEC check response' do
      updated_person = Person.find_by(hbx_id: person_id)
      expect(updated_person.mec_check_response).to eq "Applicant Not Found"
    end

    it 'should update the Person MEC check date' do
      updated_person = Person.find_by(hbx_id: person_id)
      expect(updated_person.mec_check_date).not_to be_nil
    end
  end
end