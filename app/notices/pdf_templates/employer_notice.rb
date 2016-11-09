module PdfTemplates
  class EmployerNotice
    include Virtus.model

    attribute :primary_fullname, String
    attribute :primary_identifier, String
    attribute :notice_date, Date
    attribute :application_date, Date
    attribute :employer_name, String
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :broker, PdfTemplates::Broker
    attribute :hbe, PdfTemplates::Hbe
    attribute :open_enrollment_end_on, Date
    attribute :start_on, Date
    attribute :legal_name, String
    attribute :benefit_group_package_name, String
    attribute :metal_leval, String
    attribute :carrier, String
    attribute :generate_url, String
    attribute :reference_plan, Object
    attribute :family_contribution, String
    attribute :data, Hash
    attribute :plan_year, String
    attribute :coverage_end_on, Date
    attribute :coverage_start_on, Date
    attribute :to, String
    attribute :plan, PdfTemplates::Plan
    attribute :trigger_type, String
    attribute :census_employees, Array

    def shop?
      return true
    end
  end
end
