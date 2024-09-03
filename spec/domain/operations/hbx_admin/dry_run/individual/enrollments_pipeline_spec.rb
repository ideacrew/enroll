# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxAdmin::DryRun::Individual::EnrollmentsPipeline do
  let(:family)       { FactoryBot.create(:family, :with_primary_family_member) }
  let(:effective_on) { TimeKeeper.date_of_record.beginning_of_year }
  let(:aasm_state)   { 'auto_renewing' }

  let!(:enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      :with_enrollment_members,
      :individual_assisted,
      family: family,
      aasm_state: aasm_state,
      effective_on: effective_on,
      enrollment_members: family.family_members
    )
  end

  context 'with valid data' do
    it 'should return success' do
      result = described_class.new.call(
        effective_on: effective_on,
        aasm_states: [aasm_state]
      )
      expect(result).to be_success
    end
  end
end