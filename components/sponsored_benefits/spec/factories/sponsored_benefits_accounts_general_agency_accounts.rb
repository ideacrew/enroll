# frozen_string_literal: true

FactoryBot.define do
  factory :sponsored_benefits_accounts_general_agency_account, class: '::SponsoredBenefits::Accounts::GeneralAgencyAccount' do
    start_on { TimeKeeper.date_of_record - 10.days }
    end_on { TimeKeeper.date_of_record + 10.days }
    aasm_state { 'active'}
  end
end