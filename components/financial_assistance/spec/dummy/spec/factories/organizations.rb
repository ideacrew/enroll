# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    legal_name  { "Turner Agency, Inc" }
    dba         { "Turner Brokers" }
    home_page   { "http://www.example.com" }
    office_locations  do
      [FactoryBot.build(:office_location, :primary),
       FactoryBot.build(:office_location)]
    end

    # fein do
      #Forgery('basic').text(:allow_lower   => false,
      #                      :allow_upper   => false,
      #                      :allow_numeric => true,
      #                      :allow_special => false, :exactly => 9)
    # end

    trait :with_active_plan_year do
      before :create do |organization, _evaluator|
        organization.employer_profile = FactoryBot.create :employer_profile, organization: organization, registered_on: Date.new(2015,12,1)
      end
      after :create do |organization, _evaluator|
        start_on = TimeKeeper.date_of_record.beginning_of_month
        active_plan_year = FactoryBot.create :plan_year, employer_profile: organization.employer_profile, aasm_state: "active",
                                                         :start_on => start_on, :end_on => start_on + 1.year - 1.day, :open_enrollment_start_on => (start_on - 30).beginning_of_month, :open_enrollment_end_on => (start_on - 30).beginning_of_month + 1.weeks, fte_count: 5
        FactoryBot.create :benefit_group, :with_valid_dental, plan_year: active_plan_year
      end
    end

    trait :with_active_plan_year_and_without_dental do
      before :create do |organization, _evaluator|
        organization.employer_profile = FactoryBot.create :employer_profile, organization: organization, registered_on: Date.new(2015,12,1)
      end
      after :create do |organization, _evaluator|
        start_on = TimeKeeper.date_of_record.beginning_of_month
        active_plan_year = FactoryBot.create :plan_year, employer_profile: organization.employer_profile, aasm_state: "active",
                                                         :start_on => start_on, :end_on => start_on + 1.year - 1.day, :open_enrollment_start_on => (start_on - 30).beginning_of_month, :open_enrollment_end_on => (start_on - 30).beginning_of_month + 1.weeks, fte_count: 5
        FactoryBot.create :benefit_group, plan_year: active_plan_year
      end
    end

    trait :with_expired_and_active_plan_years do
      before :create do |organization, _evaluator|
        organization.employer_profile = FactoryBot.create :employer_profile, organization: organization, registered_on: Date.new(2015,12,1)
      end
      after :create do |organization, _evaluator|
        start_on = TimeKeeper.date_of_record.beginning_of_month - 1.year
        expired_plan_year = FactoryBot.create :plan_year, employer_profile: organization.employer_profile, aasm_state: "expired",
                                                          :start_on => start_on, :end_on => start_on + 1.year - 1.day, :open_enrollment_start_on => (start_on - 30).beginning_of_month, :open_enrollment_end_on => (start_on - 30).beginning_of_month + 1.weeks, fte_count: 5
        start_on = TimeKeeper.date_of_record.beginning_of_month
        active_plan_year = FactoryBot.create :plan_year, employer_profile: organization.employer_profile, aasm_state: "active",
                                                         :start_on => start_on, :end_on => start_on + 1.year - 1.day, :open_enrollment_start_on => (start_on - 30).beginning_of_month, :open_enrollment_end_on => (start_on - 30).beginning_of_month + 1.weeks, fte_count: 5
        FactoryBot.create :benefit_group, :with_valid_dental, plan_year: expired_plan_year
        FactoryBot.create :benefit_group, :with_valid_dental, plan_year: active_plan_year
      end
    end

    trait :with_active_and_renewal_plan_years do
      before :create do |organization, _evaluator|
        organization.employer_profile = FactoryBot.create :employer_profile, organization: organization
      end
      after :create do |organization, _evaluator|
        start_on = (TimeKeeper.date_of_record + 2.months).beginning_of_month - 1.year
        active_plan_year = FactoryBot.create :plan_year, employer_profile: organization.employer_profile, aasm_state: "active", :start_on => start_on, :end_on => start_on + 1.year - 1.day, fte_count: 5
        # TODO: This was never assigned to anything
        # start_on = (TimeKeeper.date_of_record + 2.months).beginning_of_month
        renewing_plan_year = FactoryBot.create(:future_plan_year, employer_profile: organization.employer_profile, aasm_state: "renewing_enrolling")
        FactoryBot.create :benefit_group, :with_valid_dental, plan_year: active_plan_year
        FactoryBot.create :benefit_group, :with_valid_dental, plan_year: renewing_plan_year
      end
    end

    trait :with_draft_and_canceled_plan_years do
      before :create do |organization, _evaluator|
        organization.employer_profile = FactoryBot.create :employer_profile, organization: organization, registered_on: Date.new(2015,12,1)
      end
      after :create do |organization, _evaluator|
        start_on = (TimeKeeper.date_of_record + 1.month).beginning_of_month - 1.year
        FactoryBot.create :plan_year, employer_profile: organization.employer_profile, aasm_state: "canceled",
                                      :start_on => start_on, :end_on => start_on + 1.year - 1.day, :open_enrollment_start_on => (start_on - 30).beginning_of_month, :open_enrollment_end_on => (start_on - 30).beginning_of_month + 1.weeks, fte_count: 5
        FactoryBot.create :plan_year, employer_profile: organization.employer_profile, aasm_state: "draft",
                                      :start_on => start_on, :end_on => start_on + 1.year - 1.day, :open_enrollment_start_on => (start_on - 30).beginning_of_month, :open_enrollment_end_on => (start_on - 30).beginning_of_month + 1.weeks, fte_count: 5
      end
    end

    trait :with_conversion_expired_and_renewing_canceled_plan_years do
      before :create do |organization, _evaluator|
        organization.employer_profile = FactoryBot.create :employer_profile, organization: organization, registered_on: Date.new(2015,12,1), profile_source: "conversion"
      end
      after :create do |organization, _evaluator|
        start_on = TimeKeeper.date_of_record.beginning_of_month - 1.year
        con_expired_plan_year = FactoryBot.create :plan_year, employer_profile: organization.employer_profile, aasm_state: "conversion_expired",
                                                              :start_on => start_on, :end_on => start_on + 1.year - 1.day, :open_enrollment_start_on => (start_on - 30).beginning_of_month,
                                                              :open_enrollment_end_on => (start_on - 30).beginning_of_month + 1.weeks, fte_count: 5, is_conversion: true
        start_on = TimeKeeper.date_of_record.beginning_of_month
        renewing_canceled_plan_year = FactoryBot.create :plan_year, employer_profile: organization.employer_profile, aasm_state: "renewing_canceled",
                                                                    :start_on => start_on, :end_on => start_on + 1.year - 1.day, :open_enrollment_start_on => (start_on - 30).beginning_of_month, :open_enrollment_end_on => (start_on - 30).beginning_of_month + 1.weeks, fte_count: 5
        FactoryBot.create :benefit_group, :with_valid_dental, plan_year: con_expired_plan_year
        FactoryBot.create :benefit_group, :with_valid_dental, plan_year: renewing_canceled_plan_year
      end
    end
  end

  trait :conversion_employer_with_expired_and_active_plan_years do
    before :create do |organization, _evaluator|
      organization.employer_profile = FactoryBot.create :employer_profile, organization: organization, registered_on: Date.new(2017,12,1), profile_source: "conversion"
    end
    after :create do |organization, _evaluator|
      start_on = TimeKeeper.date_of_record.beginning_of_month - 1.year
      expired_plan_year = FactoryBot.create :plan_year, employer_profile: organization.employer_profile, aasm_state: "expired",
                                                        :start_on => start_on, :end_on => start_on + 1.year - 1.day, :open_enrollment_start_on => (start_on - 30).beginning_of_month, :open_enrollment_end_on => (start_on - 30).beginning_of_month + 1.weeks, fte_count: 5, :is_conversion => true
      start_on = TimeKeeper.date_of_record.beginning_of_month
      active_plan_year = FactoryBot.create :plan_year, employer_profile: organization.employer_profile, aasm_state: "active",
                                                       :start_on => start_on, :end_on => start_on + 1.year - 1.day, :open_enrollment_start_on => (start_on - 30).beginning_of_month, :open_enrollment_end_on => (start_on - 30).beginning_of_month + 1.weeks, fte_count: 5, :is_conversion => true
      FactoryBot.create :benefit_group, :with_valid_dental, plan_year: expired_plan_year
      FactoryBot.create :benefit_group, :with_valid_dental, plan_year: active_plan_year
    end
  end

  factory :broker_agency, class: Organization do
    sequence(:legal_name) {|n| "Broker Agency#{n}" }
    sequence(:dba) {|n| "Broker Agency#{n}" }
    fein do
      Forgery('basic').text(:allow_lower => false,
                            :allow_upper => false,
                            :allow_numeric => true,
                            :allow_special => false, :exactly => 9)
    end
    home_page   { "http://www.example.com" }
    office_locations  do
      [FactoryBot.build(:office_location, :primary),
       FactoryBot.build(:office_location)]
    end

    after(:create) do |organization|
      FactoryBot.create(:broker_agency_profile, organization: organization)
    end

    trait :shop_only do
      after(:create) do |organization|
        FactoryBot.create(:broker_agency_profile, market_kind: "shop", organization: organization)
      end
    end

    trait :ivl_only do
      after(:create) do |organization|
        FactoryBot.create(:broker_agency_profile, market_kind: "individual", organization: organization)
      end
    end

    trait :both_ivl_and_shop do
      after(:create) do |organization|
        FactoryBot.create(:broker_agency_profile, market_kind: "both", organization: organization)
      end
    end
  end

  factory :employer, class: Organization do
    legal_name { Forgery(:name).company_name }
    dba { legal_name }

    fein do
      Forgery('basic').text(:allow_lower => false,
                            :allow_upper => false,
                            :allow_numeric => true,
                            :allow_special => false, :exactly => 9)
    end

    office_locations  do
      [FactoryBot.build(:office_location, :primary),
       FactoryBot.build(:office_location)]
    end

    before :create do |organization, _evaluator|
      organization.employer_profile = FactoryBot.create :employer_profile, organization: organization
    end

    trait :with_insured_employees do
      after :create do |organization, _evaluator|

        plan_year = FactoryBot.create :next_month_plan_year, employer_profile: organization.employer_profile
        plan_year.benefit_groups.push(benefit_group = FactoryBot.create(:benefit_group, plan_year: plan_year, relationship_benefits: [FactoryBot.build(:relationship_benefit)]))

        # data to create an enrollment
        family = FactoryBot.create(:family, :with_primary_family_member)
        household = FactoryBot.create(:household, family: family)
        hbx_enrollment_member = FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: TimeKeeper.date_of_record.beginning_of_month)
        hbx_enrollment = FactoryBot.create(:hbx_enrollment, household: household, plan: FactoryBot.create(:plan), benefit_group: benefit_group, hbx_enrollment_members: [hbx_enrollment_member], coverage_kind: "health")
        # end of data to create an enrollment

        FactoryBot.create_list(:census_employee, 1, :with_enrolled_census_employee, employer_profile_id: organization.employer_profile.id).tap do |census_employees|
          census_employees.each do |census_employee|
            census_employee.aasm_state = "employee_role_linked"
            census_employee.benefit_group_assignments.create benefit_group: benefit_group, start_on: benefit_group.start_on, aasm_state: "coverage_selected", hbx_enrollment_id: hbx_enrollment.id

            person = FactoryBot.create :person, first_name: census_employee.first_name, middle_name: census_employee.middle_name, last_name: census_employee.last_name, ssn: census_employee.ssn, gender: census_employee.gender
            person.employee_roles.build person: person, hired_on: census_employee.hired_on, employer_profile_id: organization.employer_profile.id, census_employee_id: census_employee.id

            hbx_enrollment.benefit_group_assignment_id = census_employee.benefit_group_assignments.first.id
            hbx_enrollment.save!
            census_employee.save!
            person.save!
          end
        end
      end
    end
  end

  factory :broker, class: Organization do
    sequence(:legal_name) {|n| "Broker Agency#{n}" }
    sequence(:dba) {|n| "Broker Agency#{n}" }
    sequence(:fein, 200_000_000)
    home_page   { "http://www.example.com" }
    office_locations  do
      [FactoryBot.build(:office_location, :primary),
       FactoryBot.build(:office_location)]
    end

    before :create do |organization, _evaluator|
      organization.broker_agency_profile = FactoryBot.build :broker_agency_profile, organization: organization
    end
  end


  factory :general_agency, class: Organization do
    legal_name { Forgery(:name).company_name }
    dba { legal_name }

    fein do
      Forgery('basic').text(:allow_lower => false,
                            :allow_upper => false,
                            :allow_numeric => true,
                            :allow_special => false, :exactly => 9)
    end

    transient do
      general_agency_traits { [] }
      general_agency_attributes { {} }
    end

    before :create do |organization, _evaluator|
      organization.office_locations.push FactoryBot.build :office_location, :primary
    end

    after :create do |organization, evaluator|
      FactoryBot.create :general_agency_profile, *Array.wrap(evaluator.general_agency_traits) + [:with_staff], evaluator.general_agency_attributes.merge(organization: organization)
    end
  end

  factory :general_agency_with_organization, class: Organization do
    sequence(:legal_name) {|n| "General Agency#{n}" }
    sequence(:dba) {|n| "General Agency#{n}" }
    fein do
      Forgery('basic').text(:allow_lower => false,
                            :allow_upper => false,
                            :allow_numeric => true,
                            :allow_special => false, :exactly => 9)
    end
    home_page   { "http://www.example.com" }
    office_locations  do
      [FactoryBot.build(:office_location, :primary),
       FactoryBot.build(:office_location)]
    end

    after(:create) do |organization|
      FactoryBot.create(:general_agency_profile, organization: organization)
    end
  end
end
