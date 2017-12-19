module PdfTemplates
  class GeneralAgencyNotice
    include Virtus.model

    attribute :notification_type, String
    attribute :mpi_indicator, String
    attribute :general_agency_hbx_id, String
    attribute :primary_fullname, String
    attribute :general_agency_name, String
    attribute :general_agency, String
    attribute :general_agent_email, String
    attribute :employer, String
    attribute :employer_fullname, String
    attribute :broker_fullname, String
    attribute :effective_on, Date
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :hbe, PdfTemplates::Hbe
    attribute :broker, PdfTemplates::Broker
    attribute :general_agency_account_start_on, Date

    def shop?
      return true
    end

    def general_agency_notice?
      return true
  	end

    def employee_notice?
      return false
    end

    def employer_notice?
      return false
    end

  end
end
