FactoryBot.define do
  factory :general_agency_account do
    employer_profile { FactoryBot.create(:employer_profile) }
    start_on { TimeKeeper.date_of_record - 10.days }
    end_on { TimeKeeper.date_of_record + 10.days }
    general_agency_profile_id { FactoryBot.create(:general_agency_profile).id }
  end
end
