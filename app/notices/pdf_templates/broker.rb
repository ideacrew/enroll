module PdfTemplates
  class Broker
    include Virtus.model

    attribute :primary_fullname, String
    attribute :first_name, String
    attribute :last_name, String
    attribute :organization, String
    attribute :address, PdfTemplates::NoticeAddress
    attribute :phone, String
    attribute :email, String
    attribute :web_address, String
    attribute :employer_profile, EmployerProfile
    attribute :broker_agency_profile, BrokerAgencyProfile
    attribute :terminated_broker_account, BrokerAgencyAccount
    attribute :broker, PdfTemplates::Broker
    attribute :hbe, PdfTemplates::Hbe
    attribute :address, PdfTemplates::NoticeAddress
    attribute :mpi_indicator, String

    def shop?
      false
    end
  end
end
