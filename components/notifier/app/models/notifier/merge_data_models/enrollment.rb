module Notifier
  class MergeDataModels::Enrollment
    include Virtus.model
    include ActiveModel::Model
    include Notifier::MergeDataModels::TokenBuilder

    attribute :coverage_start_on, String
    attribute :coverage_end_on, String
    attribute :plan_name, String
    attribute :enrolled_count, String
    # attribute :metal_level, String
    attribute :coverage_kind, String
    # attribute :plan_carrier, String
    attribute :employee_responsible_amount, String
    attribute :employer_responsible_amount, String
    attribute :employee_first_name, String
    attribute :employee_last_name, String
    attribute :latest_active_enrollment, String
    attribute :coverage_year, String
    attribute :plan_carrier, String
    attribute :responsible_amount, String
    attribute :family_deductible, String
    attribute :deductible, String
    attribute :phone, String
    attribute :created_at, String
    attribute :premium_amount, String
    attribute :aasm_state, String
    attribute :aptc_amount, String
    attribute :subscriber, MergeDataModels::Person
    attribute :enrollees, Array[MergeDataModels::Person]
    attribute :health_plan, Boolean
    attribute :enrolles_count, Integer

    def self.stubbed_object
      Notifier::MergeDataModels::Enrollment.new({
        coverage_start_on: TimeKeeper.date_of_record.beginning_of_year,
        coverage_end_on: TimeKeeper.date_of_record.end_of_month,
        latest_active_enrollment: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        plan_name: 'KP SILVER',
        enrolled_count: '2',
        coverage_kind: 'dental',
        employer_responsible_amount: '$250.0',
        employee_responsible_amount: '$90.0',
        employee_first_name: 'David',
        employee_last_name: 'Finch',
        coverage_year: '2018',
        plan_carrier: "Kaiser",
        enrollees: [Notifier::MergeDataModels::Person.stubbed_object]
        })
    end
  end
end
