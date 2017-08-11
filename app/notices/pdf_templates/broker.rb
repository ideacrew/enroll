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
  end
end
