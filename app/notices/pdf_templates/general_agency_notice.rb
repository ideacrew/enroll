module PdfTemplates
  class GeneralAgencyNotice
    include Virtus.model

    attribute :primary_fullname, String
    attribute :primary_identifier, String
    attribute :primary_address, PdfTemplates::NoticeAddress
    attribute :employer, PdfTemplates::EmployerStaff
    attribute :broker, PdfTemplates::GeneralAgency
    attribute :hbe, PdfTemplates::Hbe
    attribute :plan, PdfTemplates::Plan
    attribute :employer_name, String
    attribute :broker_agency, String
    attribute :mpi_indicator, String
    attribute :termination_date, Date
    attribute :first_name, String
    attribute :last_name, String
    attribute :hbx_id, String
    attribute :employer_first_name, String
    attribute :employer_last_name, String
    attribute :employer_email, String
    attribute :ga_terminated_on, Date

    def shop?
      return true
  end

  def broker?
      return true
  end

  def employee_notice?
      true
  end

end
end