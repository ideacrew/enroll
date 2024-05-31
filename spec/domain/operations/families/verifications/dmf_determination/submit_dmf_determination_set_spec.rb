# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Families::Verifications::DmfDetermination::SubmitDmfDeterminationSet, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  let(:person) { FactoryBot.create(:person) }
  let(:person2) { FactoryBot.create(:person) }

  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:family2) { FactoryBot.create(:family, :with_primary_family_member, person: person2) }

  before do
    allow(EnrollRegistry[:alive_status].feature).to receive(:is_enabled).and_return(true)
    allow(Family).to receive(:enrolled_members_with_ssn).and_return([family, family2])
  end

  context 'success' do
    before do
      @result = subject.call
    end

    it 'should return success' do
      expect(@result).to be_success
    end

    it "should create jobs" do
      jobs = ::Transmittable::Job.where(key: :dmf_determination)
      expect(jobs.size).to eq(1)

      job = jobs.first
      expect(job.process_status.latest_state).to eq :initial
    end
  end
end