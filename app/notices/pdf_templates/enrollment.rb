module PdfTemplates
  class Enrollment
    include Virtus.model

    attribute :enrollees, Array[String]
    attribute :plan_name, String
    attribute :monthly_premium_cost, String
  end
end