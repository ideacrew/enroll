module PdfTemplates
  class Enrollment
    include Virtus.model

    attribute :enrollees, Array[String]
    attribute :premium, String
    attribute :employee_cost, String
    attribute :phone, String
    attribute :effective_on, Date
    attribute :terminated_on, Date
    attribute :waived_on, Date
    attribute :selected_on, Date
    attribute :aptc_amount, String
    attribute :responsible_amount, String
    attribute :plan, PdfTemplates::Plan
    attribute :enrolled_count, String
  end
end
