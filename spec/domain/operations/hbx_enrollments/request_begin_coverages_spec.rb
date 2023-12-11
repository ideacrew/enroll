# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::HbxEnrollments::RequestBeginCoverages, dbclean: :after_each do

  let(:family)      { FactoryBot.create(:family, :with_primary_family_member) }
  let!(:enrollment) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, aasm_state: "auto_renewing") }

  describe 'success' do
    let(:result) { described_class.new.call({}) }

    it 'succeeds with message' do
      expect(result.success?).to be_truthy
      expect(result.value!).to eq("Successfully published event: #{} to request beginning coverage for all IVL renewal enrollments effective on #{enrollment.start_on}.")
    end
  end
end
