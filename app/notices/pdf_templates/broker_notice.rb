module PdfTemplates
  class BrokerNotice
    include Virtus.model

    attribute :primary_fullname, String
    attribute :primary_identifier, String
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :broker, PdfTemplates::Broker
    attribute :hbe, PdfTemplates::Hbe
    attribute :plan, PdfTemplates::Plan
    attribute :first_name,String
    attribute :last_name, String

    def shop?
      return true
    end

    def employee_notice?
      return false
    end

    def general_agency?
      false
    end
  end
end