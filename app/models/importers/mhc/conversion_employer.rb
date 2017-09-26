module Importers::Mhc
  class ConversionEmployer < Importers::ConversionEmployer

    CARRIER_MAPPING = {
      "bmc healthnet plan"=>"BMCHP", 
      "fallon health"=>"FCHP", 
      "health new england"=>"HNE"
    }

    attr_accessor :fein,
      :assigned_employer_id,
      :sic_code,
      :primary_location_county_fips,
      :primary_location_zip,
      :mailing_location_zip

  end
end
