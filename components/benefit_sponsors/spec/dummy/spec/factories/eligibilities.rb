# frozen_string_literal: true

FactoryBot.define do
  factory :eligibility, :class => 'Eligibilities::Osse::Eligibility' do

    title { 'Osse Eligibility' }
    description { 'Osse Eligibility' }
    start_on { TimeKeeper.date_of_record.beginning_of_month }
    end_on { nil }
    status { 'status' }

    trait :with_evidences do
      after :build do |eligibility, _evaluator|
        eligibility.evidences << build(:osse_evidence)
      end
    end

    trait :with_subject do
      after :build do |eligibility, _evaluator|
        eligibility.subject = build(:subject)
      end
    end
  end
end
