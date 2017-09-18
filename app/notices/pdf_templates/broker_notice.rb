module PdfTemplates
  class BrokerNotice
    include Virtus.model

    attribute :primary_fullname, String
    attribute :primary_identifier, String
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :employer, PdfTemplates::EmployerStaff
    attribute :broker, PdfTemplates::Broker
    attribute :hbe, PdfTemplates::Hbe
    attribute :plan, PdfTemplates::Plan
    attribute :employer_name, String
    attribute :broker_agency, String
    attribute :mpi_indicator, String

    def shop?
      return true
    end

    def broker?
      return true
    end

    def employee_notice?
      return false
    end
  end
end
