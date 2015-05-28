FactoryGirl.define do
  factory :employer_profile do
    organization            { FactoryGirl.build(:organization) }
    entity_kind             "c_corporation"
    broker_agency_profile   { FactoryGirl.create(:broker_agency_profile)}
    writing_agent           { FactoryGirl.create(:broker_role)}
  end
end
