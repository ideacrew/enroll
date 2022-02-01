# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Application::FindDraft, dbclean: :after_each do
  let!(:person) do
    FactoryBot.create(:person,
                      :with_consumer_role,
                      :with_ssn,
                      first_name: 'Person11')
  end
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:draft_application1) do
    FactoryBot.create(:application,
                      family_id: family.id,
                      created_at: TimeKeeper.date_of_record,
                      aasm_state: "draft",
                      effective_date: TimeKeeper.date_of_record)
  end

  let!(:draft_application2) do
    FactoryBot.create(:application,
                      family_id: BSON::ObjectId.new,
                      aasm_state: "draft",
                      created_at: TimeKeeper.date_of_record.yesterday,
                      effective_date: TimeKeeper.date_of_record)
  end

  let(:result) { subject.call(params: {family_id: family.id}) }
  let(:application) { FinancialAssistance::Application.find(result.success) }

  it 'should return latest draft created application' do
    expect(result.success?).to be_truthy
    expect(result.success).to eq draft_application1
    expect(result.success.created_at).to eq TimeKeeper.date_of_record
  end
end
