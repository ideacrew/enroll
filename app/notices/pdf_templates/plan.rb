module PdfTemplates
  class Plan
    include Virtus.model

    attribute :open_enrollment_start_on, Date
    attribute :open_enrollment_end_on, Date
    attribute :coverage_start_on, Date
    attribute :coverage_end_on, Date

  end
end
