# frozen_string_literal: true

FactoryBot.define do
  factory :request_result, :class => 'Eligibilities::RequestResult' do
    result { 'ineligile' }
    source { 'FDSH MEDI' }
    source_transaction_id { "6228d83f6b0cc2000ccc9ea9" }
    code { "HS000000" }
    code_description { nil }
  end
end
