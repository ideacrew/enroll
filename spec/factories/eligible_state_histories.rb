# frozen_string_literal: true

FactoryBot.define do
  factory :eligible_state_history, class: 'Eligible::StateHistory' do
    effective_on { TimeKeeper.date_of_record.beginning_of_month }
    is_eligible { true }
    from_state { :draft }
    to_state { :eligible }
    transition_at { TimeKeeper.date_of_record }
    reason { 'met minimum criteria' }
    comment { 'consumer provided proper documentation' }

    before(:create) do |instance|
      instance.event = :mark_eligible
    end
  end
end
