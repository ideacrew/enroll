# frozen_string_literal: true

FactoryBot.define do
  factory :benefit_sponsors_organizations_issuer_profile, class: 'IssuerProfile' do

    transient do
      office_locations_count { 1 }
      assigned_site { nil }
      legal_name { "Blue Cross Blue Shield" }
    end

    after(:build) do |profile, evaluator|
      if profile.organization.blank?
        profile.organization = if evaluator.assigned_site
                                 FactoryBot.build(:benefit_sponsors_organizations_general_organization, legal_name: evaluator.legal_name, site: evaluator.assigned_site)
                               else
                                 FactoryBot.build(:benefit_sponsors_organizations_general_organization, :with_site, legal_name: evaluator.legal_name)
                               end
      end
    end

    after(:build) do |profile, evaluator|
      profile.office_locations << build_list(:benefit_sponsors_locations_office_location, evaluator.office_locations_count, :primary)
    end
  end
end
