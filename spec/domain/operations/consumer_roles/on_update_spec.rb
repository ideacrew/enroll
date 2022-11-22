# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::ConsumerRoles::OnUpdate, dbclean: :after_each do

  subject do
    described_class.new.call(
      { payload: { gid: consumer_role_gid, previous: { is_applying_coverage: false } },
        subscriber_logger: Logger.new("#{Rails.root}/log/testing.log") }
    )
  end

  after :all do
    logger_name = "#{Rails.root}/log/testing.log"
    File.delete(logger_name) if File.exist?(logger_name)
  end

  let(:consumer_role_gid) { consumer_role.to_global_id.uri }

  context 'with invalid params' do
    let(:params) { { subscriber_logger: Logger.new("#{Rails.root}/log/testing.log") } }

    it 'returns failure' do
      expect(described_class.new.call(params).failure).to eq(
        "Invalid params: #{params}. Must have keys :payload(should be an instance if Hash) and :subscriber_logger(should be an instance if Logger)"
      )
    end
  end

  context 'when consumer role id is nil' do
    let(:consumer_role_gid) { nil }

    it 'returns failure' do
      expect(subject.failure).to eq "Unable to find gid: #{consumer_role_gid}"
    end
  end

  describe 'when person and consumer role exists' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:consumer_role) { person.consumer_role }

    context 'if person does not have an active enrollment' do
      it 'returns success' do
        expect(subject.success).to eq(
          "ConsumerRole DetermineVerifications success: Successfully triggered Hub Calls for ConsumerRole with person_hbx_id: #{person.hbx_id}"
        )
      end

      it 'updates consumer_role state to verification_outstanding' do
        expect(consumer_role.aasm_state).to eq 'unverified'
        subject
        expect(consumer_role.reload.aasm_state).to eq 'verification_outstanding'
      end
    end

    context 'if person has an active enrollment' do
      let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
      let!(:enrollment) do
        FactoryBot.create(
          :hbx_enrollment,
          :with_enrollment_members,
          :individual_assisted,
          family: family,
          consumer_role_id: consumer_role.id,
          enrollment_members: family.family_members
        )
      end

      it 'returns failure' do
        expect(subject.failure).to eq 'Consumer has an active enrollment'
      end
    end
  end

  context "when consumer's applicant status did not change" do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }

    it 'returns failure' do
      result = described_class.new.call(
        { payload: { gid: person.consumer_role.to_global_id.uri, previous: {} },
          subscriber_logger: Logger.new("#{Rails.root}/log/testing.log") }
      )
      expect(result.failure).to eq "Consumer's applicant status did not change"
    end
  end

  context 'when person is not applying for coverage' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:consumer_role) do
      role = person.consumer_role
      role.update_attributes(is_applying_coverage: false)
      role
    end

    it 'returns failure' do
      result = described_class.new.call(
        { payload: { gid: consumer_role_gid, previous: { is_applying_coverage: true } },
          subscriber_logger: Logger.new("#{Rails.root}/log/testing.log") }
      )
      expect(result.failure).to eq 'Consumer is not applying for coverage.'
    end
  end
end
