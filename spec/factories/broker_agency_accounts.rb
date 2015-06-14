FactoryGirl.define do
  factory :broker_agency_account do
    start_on  Date.current
    broker_agency_profile   { FactoryGirl.create(:broker_agency_profile)}
    writing_agent           { FactoryGirl.create(:broker_role)}
  end

end
