FactoryGirl.define do
  factory :broker_agency do
    name "Trusty Broker, Inc"
    market_kind "both"
    primary_broker { FactoryGirl.build(:broker_role) }

    factory :with_writing_agents do
      after(:create) do |broker_agency|
        create_list(:writing_agent, 5, broker_agency: broker_agency)
      end
    end

  end

end
