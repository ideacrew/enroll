FactoryGirl.define do
  factory :broker_agency do
    name "Trusty Broker, Inc"
    market_kind "both"
    primary_broker { FactoryGirl.build(:broker) }

    factory :broker_agency_with_writing_agents do
      transient do
        writing_agents_count 5
      end

      after(:create) do |broker_agency, evaluator|
        create_list(:broker, evaluator.writing_agents_count, writing_agent: broker)
      end
    end

  end

end
