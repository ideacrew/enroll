module Notifier
  class MergeDataModels::PlanYear
    include Virtus.model

    attribute :open_enrollment_start_on, Date
    attribute :open_enrollment_end_on, Date
    attribute :start_on, Date
    attribute :end_on, Date

    attribute :renewal_open_enrollment_start_on, Date
    attribute :renewal_open_enrollment_end_on, Date
    attribute :renewal_start_on, Date
    attribute :renewal_end_on, Date

    attribute :carrier_name, String
    attribute :renewal_carrier_name, String

    attribute :warnings, Array[String]
    attribute :errors, Array[String]

    attribute :binder_due_date, Date
    attribute :renewal_binder_due_data, Date


    def self.stubbed_object
      Notifier::MergeDataModels::PlanYear.new({
        open_enrollment_start_on: '09/1/2017',
        open_enrollment_end_on: '09/10/2017',
        start_on: '10/01/2017',
        end_on: '09/30/2018',
        renewal_open_enrollment_start_on: '09/1/2017',
        renewal_open_enrollment_end_on: '09/10/2017',
        renewal_start_on: '10/01/2017',
        renewal_end_on: '09/30/2018',
        carrier_name: 'Kaiser',
        renewal_carrier_name: 'Kaiser',
        binder_due_date: '09/25/2017',
        renewal_binder_due_data: '09/25/2017'
      })
    end
  end
end
