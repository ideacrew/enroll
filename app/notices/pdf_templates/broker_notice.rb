module PdfTemplates
  class BrokerNotice
    include Virtus.model

    attribute :primary_fullname, String
    attribute :primary_identifier, String
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :broker, PdfTemplates::Broker
    attribute :hbe, PdfTemplates::Hbe
    attribute :plan, PdfTemplates::Plan
    attribute :employer_first_name, String
    attribute :employer_last_name, String
    attribute :employer_name, String
    attribute :broker_agency, String
    attribute :mpi_indicator, String
    attribute :assignment_date, Date
    attribute :assignment_end_date, Date
    attribute :hbx_id, String
    attribute :phone, String
    attribute :email, String
    attribute :first_name,String
    attribute :last_name, String
    attribute :termination_date, Date

    def shop?
      return true
    end
  end
end
