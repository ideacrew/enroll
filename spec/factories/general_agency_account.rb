FactoryGirl.define do
  factory :general_agency_account do
    employer_profile { FactoryGirl.create(:employer_profile) }
    start_on { TimeKeeper.date_of_record - 10.days }
    end_on { TimeKeeper.date_of_record + 10.days }
    general_agency_profile_id { FactoryGirl.create(:general_agency_profile).id }
  end
end
