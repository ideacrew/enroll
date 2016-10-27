module PdfTemplates
  class Enrollment
    include Virtus.model

    attribute :enrollees, Array[String]
    attribute :plan_name, String
    attribute :premium, String
    attribute :phone, String
    attribute :effective_on, Date
    attribute :selected_on, Date
    attribute :plan, PdfTemplates::Plan
  end
end
