module PdfTemplates
  class EmployeeNotice
    include Virtus.model

    attribute :primary_fullname, String
    attribute :primary_identifier, String
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :employer_name, String
    attribute :broker, PdfTemplates::Broker
    attribute :hbe, PdfTemplates::Hbe
    attribute :plan, PdfTemplates::Plan
    attribute :census_employee, PdfTemplates::CensusEmployee
    attribute :enrollment, PdfTemplates::Enrollment
    attribute :email, String
    attribute :plan_year, PdfTemplates::PlanYear
    attribute :sep, PdfTemplates::SpecialEnrollmentPeriod

    def shop?
      return true
    end

    def employee_notice?
      return true
    end
  end
end
