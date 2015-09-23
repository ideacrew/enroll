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

    def shop?
      return true
    end
  end
end
