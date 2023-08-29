# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'default enrollments namespace client specific configurations' do

  describe 'silent_transition_enrollment' do
    context 'for default value' do
      it 'returns default value false' do
        expect(
          EnrollRegistry.feature_enabled?(:silent_transition_enrollment)
        ).to be_falsey
      end
    end
  end

  describe 'cancel_superseded_terminated_enrollments' do
    context 'for default value' do
      it 'returns default value false' do
        expect(
          EnrollRegistry.feature_enabled?(:cancel_superseded_terminated_enrollments)
        ).to be_falsey
      end
    end
  end
end
