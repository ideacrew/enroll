# frozen_string_literal: true

FactoryBot.define do
  factory :subject, :class => 'Eligibilities::Osse::Subject' do
    title { 'Osse Eligibility Subject' }
    description { 'Osse Eligibility Subject' }
    key { :osse_subsidy }
    klass { 'EmployeeRole' }
  end
end