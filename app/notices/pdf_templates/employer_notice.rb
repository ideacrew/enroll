module PdfTemplates
  class EmployerNotice
    include Virtus.model

    attribute :notification_type, String
    attribute :primary_fullname, String
    attribute :employee_fullname, String
    attribute :primary_identifier, String
    attribute :employee_fullname, String
    attribute :mpi_indicator, String
    attribute :notice_date, Date
    attribute :application_date, Date
    attribute :employer_name, String
    attribute :enrollment, PdfTemplates::Enrollment
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :broker, PdfTemplates::Broker
    attribute :hbe, PdfTemplates::Hbe
    attribute :open_enrollment_end_on, Date
    attribute :coverage_end_on, Date
    attribute :coverage_start_on, Date
    attribute :to, String
    attribute :plan, PdfTemplates::Plan
    attribute :plan_year, PdfTemplates::PlanYear
    attribute :sep, PdfTemplates::SpecialEnrollmentPeriod

    def shop?
      return true
    end
  end
end
