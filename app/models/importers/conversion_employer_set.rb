module Importers
  class ConversionEmployerSet
    def headers
      [
        "Action",
        "FEIN",
        "Doing Business As",
        "Legal Name",
        "Physical Address 1",
        "Physical Address 2",
        "City",
        "State",
        "Zip",
        "Mailing Address 1",
        "Mailing Address 2",
        "City",
        "State",
        "Zip",
        "Contact First Name",
        "Contact Last Name",
        "Contact Email",
        "Contact Phone",
        "Enrolled Employee Count",
        "New Hire Coverage Policy",
        "Contact Address 1",
        "Contact Address 2",
        "City",
        "State",
        "Zip",
        "Broker Name",
        "Broker NPN",
        "TPA Name",
        "TPA FEIN",
        "Coverage Start Date",
        "Carrier Selected",
        "Plan Selection Category",
        "Plan Name",
        "Plan HIOS Id",
        "Most Enrollees - Plan Name",
        "Most Enrollees - Plan HIOS Id",
        "Reference Plan - Name",
        "Reference Plan - HIOS Id",
        "Employer Contribution -  Employee",
        "Employer Contribution - Spouse",
        "Employer Contribution - Domestic Partner",
        "Employer Contribution - Child under 26",
        "Employer Contribution - Child over 26",
        "Employer Contribution - Disabled child over 26",
        "Import Status",
        "Import Details"
      ]
    end

    def row_mapping
      [
        :action,
        :fein,
        :dba,
        :legal_name,
        :primary_location_address_1,
        :primary_location_address_2,
        :primary_location_city,
        :primary_location_state,
        :primary_location_zip,
        :mailing_location_address_1,
        :mailing_location_address_2,
        :mailing_location_city,
        :mailing_location_state,
        :mailing_location_zip,
        :ignore,
        :ignore,
        :contact_email,
        :contact_phone,
        :enrolled_employee_count,
        :new_hire_count,
        :ignore,
        :ignore,
        :ignore,
        :ignore,
        :ignore,
        :broker_name,
        :broker_npn
      ]
    end

    include ::Importers::RowSet

    def initialize(file_name, o_stream)
      @spreadsheet = Roo::Spreadsheet.open(file_name)
      @out_stream = o_stream
      @out_csv = CSV.new(o_stream)
    end

    def create_model(record_attrs)
      ::Importers::ConversionEmployer.new(record_attrs)
    end
  end
end
