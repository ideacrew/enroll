FactoryGirl.define do
  factory :phone do
    kind 'home'
    sequence(:number, 1111111111) { |n| "#{n}"}
    sequence(:extension) { |n| "#{n}"}
  end
end