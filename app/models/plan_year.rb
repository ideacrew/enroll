class PlanYear
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :employer

  # include MergingModel

  # Plan Year time period
  field :start_date, type: Date
  field :end_date, type: Date

  field :open_enrollment_start_date, type: Date
  field :open_enrollment_end_date, type: Date

  # Number of full-time employees
  field :fte_count, type: Integer, default: 0

  # Number of part-time employess
  field :pte_count, type: Integer, default: 0

  # Number of Medicare second payers
  field :msp_count, type: Integer, default: 0

  embeds_many :employee_classes, class_name: "EmployerCensus::EmployeeClass"

end
