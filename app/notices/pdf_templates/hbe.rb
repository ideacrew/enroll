module PdfTemplates
  class Hbe
    include Virtus.model

    attribute :url, String
    attribute :phone, String
    attribute :fax, String
    attribute :email, String
    attribute :tty, String
    attribute :ma_email, String
    attribute :address, PdfTemplates::NoticeAddress

  end
end
