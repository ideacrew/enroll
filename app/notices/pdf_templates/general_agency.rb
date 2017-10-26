module PdfTemplates
  class GeneralAgency
    include Virtus.model

    attribute :primary_fullname, String
    attribute :organization, String
    attribute :address, PdfTemplates::NoticeAddress
    attribute :phone, String
    attribute :email, String
    attribute :web_address, String
    attribute :mpi_indicator, String
    attribute :hbe, PdfTemplates::Hbe
    attribute :employer_profile, EmployerProfile
    attribute :broker_agency_profile, BrokerAgencyProfile
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :employer_name
    attribute :first_name, String
    attribute :last_name, String
    attribute :assignment_date, Date
    attribute :full_name, String
    attribute :hbx_id, String

    def shop?
      false
    end
  end
end
