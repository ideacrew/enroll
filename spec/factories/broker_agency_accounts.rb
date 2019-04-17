FactoryBot.define do
  factory :broker_agency_account do
    employer_profile
    start_on                { TimeKeeper.date_of_record }
    broker_agency_profile   { FactoryBot.create(:broker_agency_profile)}
    writing_agent           { FactoryBot.create(:broker_role)}
  end

end
