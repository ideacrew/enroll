module PdfTemplates
  class EligibilityNotice
    include Virtus.model

    attribute :primary_fullname, String
    attribute :primary_identifier, String
    attribute :notice_date, Date
    attribute :application_date, Date
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :enrollments, Array[PdfTemplates::Enrollment]
    
  end
end