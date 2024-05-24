# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Families::Verifications::DmfDetermination::SubmitDmfDeterminationSet, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  let(:person) { FactoryBot.create(:person, hbx_id: "732020") }
  let(:person2) { FactoryBot.create(:person, hbx_id: "732021") }

  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:family2) { FactoryBot.create(:family, :with_primary_family_member, person: person2) }

  before do
    allow(EnrollRegistry).to receive(:feature_enabled?).with(:alive_status).and_return(true)
    allow(Family).to receive(:enrolled_members_with_ssn).and_return([family, family2])
  end

  context 'success' do
    it 'should return success' do
      result = subject.call
      expect(result).to be_success
    end

    it "should create jobs" do
      jobs = ::Transmittable::Job.where(key: :started_dmf_determination)
      expect(jobs.size).to eq(2)

      job = jobs.first
      expect(job).to be_truthy
      expect(job.process_status.latest_state).to eq :transmitted
    end
  end
end
