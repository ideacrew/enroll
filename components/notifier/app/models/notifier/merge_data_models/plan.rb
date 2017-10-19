module Notifier
  class MergeDataModels::Plan
    include Virtus.model

    attribute :coverage_start_on, String
    # attribute :coverage_end_on, Date
    attribute :plan_name, String
    # attribute :metal_level, String
    # attribute :coverage_kind, String
    # attribute :plan_carrier, String
    attribute :employee_responsible_amount, String
    attribute :employer_responsible_amount, String
  end

  def self.stubbed_object
      Notifier::MergeDataModels::Plan.new({
        coverage_start_on: TimeKeeper.date_of_record.next.beginnning_of_month.strftime('%m/%d/%Y'),
        plan_name: 'KP SILVER',
        employer_responsible_amount: '$250.0',
        employee_responsible_amount: '$90.0',
      })
    end
end
