module PdfTemplates
  class BrokerNotice
    include Virtus.model

    attribute :primary_fullname, String
    attribute :primary_identifier, String
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :broker, PdfTemplates::Broker
    attribute :hbe, PdfTemplates::Hbe
    attribute :plan, PdfTemplates::Plan
    attribute :er_first_name, String
    attribute :er_last_name, String
    attribute :er_fullname, String
    attribute :er_address, String
    attribute :er_email, String
    attribute :er_phone, String
    attribute :er_legal_name, String
    attribute :employer_name, String
    attribute :broker_agency, String
    attribute :mpi_indicator, String
    attribute :employer_profile, EmployerProfile
    attribute :broker_agency_profile, BrokerAgencyProfile
    attribute :terminated_broker_account, BrokerAgencyAccount
    attribute :first_name, String
    attribute :last_name, String

    def shop?
      return true
    end

    def employee_notice?
      return true
    end
    
  end
end
