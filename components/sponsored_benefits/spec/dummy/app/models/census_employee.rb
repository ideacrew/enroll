class CensusEmployee < CensusMember
  include AASM
  include Sortable

  require 'roo'

  EMPLOYMENT_ACTIVE_STATES = %w(eligible employee_role_linked employee_termination_pending newly_designated_eligible newly_designated_linked cobra_eligible cobra_linked cobra_termination_pending)
  EMPLOYMENT_TERMINATED_STATES = %w(employment_terminated cobra_terminated rehired)
  EMPLOYMENT_ACTIVE_ONLY = %w(eligible employee_role_linked employee_termination_pending newly_designated_eligible newly_designated_linked)
  NEWLY_DESIGNATED_STATES = %w(newly_designated_eligible newly_designated_linked)
  LINKED_STATES = %w(employee_role_linked newly_designated_linked cobra_linked)
  ELIGIBLE_STATES = %w(eligible newly_designated_eligible cobra_eligible employee_termination_pending cobra_termination_pending)
  COBRA_STATES = %w(cobra_eligible cobra_linked cobra_terminated cobra_termination_pending)
  PENDING_STATES = %w(employee_termination_pending cobra_termination_pending)
  ENROLL_STATUS_STATES = %w(enroll waive will_not_participate)

  EMPLOYEE_TERMINATED_EVENT_NAME = "acapi.info.events.census_employee.terminated"
  EMPLOYEE_COBRA_TERMINATED_EVENT_NAME = "acapi.info.events.census_employee.cobra_terminated"

  field :is_business_owner, type: Boolean, default: false
  field :hired_on, type: Date
  field :employment_terminated_on, type: Date
  field :coverage_terminated_on, type: Date
  field :aasm_state, type: String
  field :expected_selection, type: String, default: "enroll"

  # Employer for this employee
  field :employer_profile_id, type: BSON::ObjectId
  field :benefit_sponsors_employer_profile_id, type: BSON::ObjectId

  # Employee linked to this roster record
  field :employee_role_id, type: BSON::ObjectId

  field :cobra_begin_date, type: Date
end