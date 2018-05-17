module Importers::Mhc
  class ConversionEmployer < Importers::ConversionEmployer

    attr_accessor :assigned_employer_id,
                  :sic_code,
                  :contact_extension,
                  :primary_location_county_fips,
                  :primary_location_zip,
                  :mailing_location_zip

    def primary_location_zip=(val = '')
      @primary_location_zip = prepend_zeros(val.to_i.to_s, 5)
    end

    def mailing_location_zip=(val = '')
      @mailing_location_zip = prepend_zeros(val.to_i.to_s, 5)
    end

    def sic_code=(val)
      @sic_code = val
    end

  end
end

