module PdfTemplates
  class EmployeeNotice
    include Virtus.model

    attribute :notification_type, String
    attribute :mpi_indicator, String
    attribute :primary_fullname, String
    attribute :primary_identifier, String
    attribute :primary_email, String
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :employer_name, String
    attribute :primary_email, String
    attribute :broker, PdfTemplates::Broker
    attribute :hbe, PdfTemplates::Hbe
    attribute :plan, PdfTemplates::Plan
    attribute :dental_plan, PdfTemplates::Plan
    attribute :census_employee, PdfTemplates::CensusEmployee
    attribute :enrollment, PdfTemplates::Enrollment
    attribute :term_enrollment, PdfTemplates::TermEnrollment
    attribute :dental_enrollment, PdfTemplates::Enrollment
    attribute :email, String
    attribute :primary_email, String
    attribute :plan_year, PdfTemplates::PlanYear
    attribute :sep, PdfTemplates::SpecialEnrollmentPeriod

    def shop?
      return true
    end

    def broker?
      return false
    end

    def general_agency_notice?
      return false
    end

    def employee_notice?
      return true
    end

    def general_agency?
      false
    end
  end
end
