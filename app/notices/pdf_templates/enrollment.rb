module PdfTemplates
  class Enrollment
    include Virtus.model

    attribute :enrollees, Array[PdfTemplates::Individual]
    attribute :premium, String
    attribute :employee_cost, String
    attribute :employer_contribution, String
    attribute :phone, String
    attribute :effective_on, Date
    attribute :selected_on, Date
    attribute :terminated_on, Date
    attribute :created_at, Date
    attribute :aptc_amount, String
    attribute :responsible_amount, String
    attribute :plan, PdfTemplates::Plan
    attribute :kind, String
    attribute :coverage_kind, String
    attribute :is_receiving_assistance, Boolean, :default => false
    attribute :plan_year, Date
    attribute :ivl_open_enrollment_start_on, Date
    attribute :ivl_open_enrollment_end_on, Date
    attribute :enrollees_count, Integer
    attribute :employee_fullname, String
    attribute :dependents_count, String
    attribute :enrolled_count, String
    attribute :dependents, Array[String]
    attribute :dependent_dob, Date
    attribute :is_congress, Boolean
  end
end
