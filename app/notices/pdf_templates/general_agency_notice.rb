module PdfTemplates
  class GeneralAgencyNotice
    include Virtus.model

    attribute :notification_type, String
    attribute :mpi_indicator, String
    attribute :primary_identifier, String
    attribute :primary_fullname, String
    attribute :general_agency_name, String
    attribute :general_agency, String
    attribute :email, String
    attribute :broker_fullname, String
    attribute :effective_on, Date
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :hbe, PdfTemplates::Hbe
    attribute :broker, PdfTemplates::Broker

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
