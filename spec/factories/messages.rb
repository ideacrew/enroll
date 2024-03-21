FactoryBot.define do
  factory :message do
    subject { "phoenix project" }
    body    { "welcome to the hbx" }

    trait :inbox_folder do
      folder { 'inbox' }
    end

    trait :sent_folder do
      folder { 'sent' }
    end

    trait :deleted_folder do
      folder { 'deleted' }
    end
  end

  factory :message1, :class=>:Message do
    subject { "test message 1" }
    body    { "welcome" }
    created_at { DateTime.new(1998,10,1) }
  end

  factory :message2, :class=>:Message do
    subject { "test message 2" }
    body    { "welcome again" }
    created_at { DateTime.new(1999,10,1) }
  end
end
