module PdfTemplates
  class BrokerTerminatedNotice
    include Virtus.model

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
