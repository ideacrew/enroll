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

    def build_primary_address
      Address.new(
        :kind => "work",
        :address_1 => primary_location_address_1,
        :address_2 => primary_location_address_2,
        :city =>  primary_location_city,
        :state => primary_location_state,
        :county => primary_location_county,
        :location_state_code => primary_location_county_fips,
        :zip => primary_location_zip
        )
    end
  end
end
