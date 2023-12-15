# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxEnrollments::RequestBeginCoverages, dbclean: :after_each do

  let(:family)      { FactoryBot.create(:family, :with_primary_family_member) }
  let(:enrollment) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, aasm_state: "auto_renewing") }
  let(:start_on) { Date.today.beginning_of_year }
  let(:end_on) { Date.today.end_of_year }
  let(:event_name) { "events.individual.enrollments.begin_coverages.request" }

  before do
    allow(HbxProfile).to receive_message_chain(:current_hbx, :benefit_sponsorship, :current_benefit_coverage_period, :start_on).and_return(start_on)
    allow(HbxProfile).to receive_message_chain(:current_hbx, :benefit_sponsorship, :current_benefit_coverage_period, :end_on).and_return(end_on)
  end

  describe 'success' do
    let(:result) { described_class.new.call({}) }

    it 'succeeds with message' do
      expect(result.success?).to be_truthy
      expect(result.value!).to eq("Successfully published event: #{event_name} to request beginning coverage for all IVL renewal enrollments effective on #{start_on}.")
    end
  end
end
