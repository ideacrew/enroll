# frozen_string_literal: true

FactoryBot.define do
  factory :financial_assistance_relationship, class: "::FinancialAssistance::Relationship" do
    kind { 'spouse' }
    applicant_id {} # TODO: implement later
    relative_id {} # TODO: implement later
  end
end
