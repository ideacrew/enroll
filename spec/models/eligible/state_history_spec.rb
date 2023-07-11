# frozen_string_literal: true

require 'rails_helper'

# Eligible module namespace for new models
module Eligible
  # Test class to test the state history model
  class TestStatusTrackable
    include Mongoid::Document

    embeds_many :state_histories,
                class_name: '::Eligible::StateHistory',
                cascade_callbacks: true,
                as: :status_trackable
  end

  RSpec.describe StateHistory, type: :model, dbclean: :after_each do
    describe 'A new model instance' do
      it { is_expected.to be_mongoid_document }
      it do
        is_expected.to have_fields(
          :effective_on,
          :from_state,
          :to_state,
          :transition_at
        )
      end
      it do
        is_expected.to have_field(:is_eligible).of_type(
          Mongoid::Boolean
        ).with_default_value_of(false)
      end

      context 'with all required fields' do
        subject { build(:eligible_state_history) }

        context 'with all required arguments' do
          it 'should be valid' do
            subject.validate
            expect(subject).to be_valid
          end

          it 'should be findable' do
            record = TestStatusTrackable.new(state_histories: [subject])
            record.save!

            new_record = TestStatusTrackable.find(record.id)
            expect(new_record.state_histories).to be_present
          end
        end
      end
    end
  end
end
