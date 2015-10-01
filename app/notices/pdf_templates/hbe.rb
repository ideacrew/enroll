module PdfTemplates
  class Hbe
    include Virtus.model

    attribute :url, String
    attribute :phone, String
    attribute :fax, Date
    attribute :email, Date
    attribute :address, PdfTemplates::NoticeAddress

  end
end
