module PdfTemplates
  class EnrollmentWithPlanData
    include Virtus.model

    attribute :enrollees, Array[String]
    attribute :plan_name, String
    attribute :premium, String
    attribute :phone, String
    attribute :effective_on, Date
    attribute :selected_on, Date
    attribute :metal_level, String
    attribute :coverage_kind, String
    attribute :plan_carrier, String
    attribute :hsa_plan, Boolean
  end
end
