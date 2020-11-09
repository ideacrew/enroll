module Notifier
  class MergeDataModels::Enrollment
    include Virtus.model
    include ActionView::Helpers::NumberHelper

    attribute :coverage_start_on, String
    attribute :effective_on, Date
    attribute :coverage_year, Integer
    attribute :plan_name, String
    attribute :employee_responsible_amount, String
    attribute :employer_responsible_amount, String
    attribute :premium_amount, String
    attribute :product, MergeDataModels::Product
    attribute :subscriber, MergeDataModels::Person
    attribute :dependents, Array[MergeDataModels::Person]
    attribute :employee_first_name, String
    attribute :employee_last_name, String
    attribute :coverage_end_on, String
    attribute :enrolled_count, String
    attribute :enrollment_kind, String
    attribute :waiver_effective_on, String
    attribute :waiver_plan_name, String
    attribute :waiver_enrolled_count, String
    attribute :waiver_coverage_end_on, String
    attribute :coverage_kind, String
    attribute :coverage_end_on_minus_60_days, String
    attribute :coverage_end_on_plus_60_days, String

    attribute :is_receiving_assistance, Boolean, :default => false
    attribute :aptc_amount, String
    attribute :responsible_amount, String
    attribute :terminated_on, Date
    attribute :submitted_at, Date
    attribute :created_at, Date
    attribute :kind, String
    attribute :open_enrollment_start_on, Date
    attribute :open_enrollment_end_on, Date

    def self.stubbed_object
      end_on = TimeKeeper.date_of_record.end_of_month
      enrollment = Notifier::MergeDataModels::Enrollment.new({
        coverage_start_on: TimeKeeper.date_of_record.next.beginning_of_month.strftime('%m/%d/%Y'),
        coverage_year: 2021,
        coverage_end_on: end_on,
        plan_name: 'Aetna GOLD',
        employer_responsible_amount: '$250.0',
        employee_responsible_amount: '$90.0',
        premium_amount: '340.0',
        enrolled_count: '2',
        enrollment_kind: "special_enrollment",
        coverage_kind: 'health',
        employee_first_name: 'David',
        employee_last_name: 'Finch',
        coverage_end_on_minus_60_days: (end_on - 60.days).strftime('%m/%d/%Y'),
        coverage_end_on_plus_60_days: (end_on + 60.days).strftime('%m/%d/%Y'),
        waiver_effective_on: TimeKeeper.date_of_record.next_month.beginning_of_month.strftime('%m/%d/%Y'),
        waiver_plan_name: 'Aetna GOLD',
        waiver_enrolled_count: '2',
        waiver_coverage_end_on: end_on,
        is_receiving_assistance: false,
        aptc_amount: '5',
        effective_on: TimeKeeper.date_of_record.next.beginning_of_month,
        responsible_amount: '458'
      })

      enrollment.subscriber = Notifier::MergeDataModels::Person.stubbed_object
      enrollment.product = Notifier::MergeDataModels::Product.stubbed_object
      enrollment.dependents = [Notifier::MergeDataModels::Person.stubbed_object]
      enrollment
    end

    def self.stubbed_object_dental
      end_on = TimeKeeper.date_of_record.end_of_month
      enrollment = Notifier::MergeDataModels::Enrollment.new({
        coverage_start_on: TimeKeeper.date_of_record.next.beginning_of_month.strftime('%m/%d/%Y'),
        coverage_end_on: end_on,
        plan_name: 'Delta Dental',
        employer_responsible_amount: '$250.0',
        employee_responsible_amount: '$90.0',
        premium_amount: '340.0',
        enrolled_count: '2',
        employee_first_name: 'David',
        employee_last_name: 'Finch',
        coverage_end_on_minus_60_days: (end_on - 60.days).strftime('%m/%d/%Y'),
        coverage_end_on_plus_60_days: (end_on + 60.days).strftime('%m/%d/%Y'),
        waiver_effective_on: TimeKeeper.date_of_record.next_month.beginning_of_month.strftime('%m/%d/%Y'),
        waiver_plan_name: 'Delta Dental',
        waiver_enrolled_count: '2',
        waiver_coverage_end_on: end_on

      })

      enrollment.subscriber = Notifier::MergeDataModels::Person.stubbed_object
      enrollment.dependents = [Notifier::MergeDataModels::Person.stubbed_object]
      enrollment
    end

    def employer_cost
      number_to_currency(employer_responsible_amount.to_f)
    end

    def employee_cost
      number_to_currency(employee_responsible_amount.to_f)
    end

    def health?
      coverage_kind == 'health'
    end

    def dental?
      coverage_kind == 'dental'
    end

    def premium
      number_to_currency(premium_amount.to_f)
    end

    def number_of_enrolled
      dependents.count + 1
    end
  end
end