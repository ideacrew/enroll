FactoryGirl.define do
  factory :family do
    association :person
    sequence(:e_case_id) {|n| "abc#{n}12xyz#{n}"}
    renewal_consent_through_year  2017
    submitted_at Time.now
    updated_at "user"

    transient do
      people [] 
    end

    trait :with_primary_family_member do
      family_members { [FactoryGirl.build(:family_member, family: self, is_primary_applicant: true, is_active: true, person: person)] }
    end

    trait :with_family_members do 
      family_members { people.map{|person| FactoryGirl.build(:family_member, family: self, is_primary_applicant: (self.person == person), is_active: true, person: person) }}
    end

    after :create do |f, evaluator|
      f.family_members.each do |family_member|
        f.households.first.add_household_coverage_member(family_member)
      end
      f.save
    end
  end
end

FactoryGirl.define do
  factory(:individual_market_family, class: Family) do
    transient do
      primary_person { FactoryGirl.create(:person, :with_consumer_role) }
    end

    family_members { [
      FactoryGirl.create(:family_member, family: self, is_primary_applicant: true, is_active: true, person: primary_person)
    ] }

    after :create do |f, evaluator|
      f.households.first.add_household_coverage_member(f.family_members.first)
    end
  end
end
