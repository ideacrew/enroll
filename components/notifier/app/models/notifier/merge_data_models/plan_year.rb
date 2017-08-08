module Notifier
  class MergeDataModels::PlanYear
    include Virtus.model

    attribute :open_enrollment_start_on, Date, default: '09/1/2017'
    attribute :open_enrollment_end_on, Date, default: '09/10/2017'
    attribute :start_on, Date, default: '10/01/2017'
    attribute :end_on, Date, default: '09/30/2018'
    attribute :carrier_name, String, default: 'Kaiser'
    attribute :warnings, Array[String]
    attribute :binder_payment_due_date, Date, default: '09/25/2017'
  end
end
