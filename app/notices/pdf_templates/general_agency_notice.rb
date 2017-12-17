module PdfTemplates
  class GeneralAgencyNotice
    include Virtus.model

    attribute :primary_identifier, String
    attribute :primary_fullname, String#legal name
    attribute :employer_name, String
    attribute :ga_email, String
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :employer, PdfTemplates::EmployerStaff
    attribute :broker, PdfTemplates::Broker
    attribute :general_agent, PdfTemplates::GeneralAgent
    attribute :hbe, PdfTemplates::Hbe
    attribute :mpi_indicator, String
    attribute :hbx_id, String
    attribute :terminated_on, Date

    def shop?
      true
    end

    def broker?
      false
    end

    def employee_notice?
      false
    end

    def general_agency?
      true
    end
  end
end