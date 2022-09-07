# frozen_string_literal: true

FactoryBot.define do
  factory :grant, :class => 'Eligibilities::Osse::Grant' do
    title { 'Osse Eligibility Grant' }
    description { 'Osse Eligibility Grant' }
    key { :minimum_participation_relaxed }
    start_on { TimeKeeper.date_of_record.beginning_of_month }
  end
end