class RateReference
  include Mongoid::Document

  field :zip_code, type: String
  field :county_name, type: String
  field :rating_region, type: String
  field :zip_code_in_multiple_counties, type: Boolean, default: false

  validates_presence_of :zip_code, :county_name, :rating_region, :zip_code_in_multiple_counties
  validates_uniqueness_of :zip_code, :scope => :county_name
  validates_uniqueness_of :county_name, :scope => :zip_code

  validates_inclusion_of :rating_region, :in => market_rating_areas, :allow_blank => false

  # TODO: Lookup of rating area string for a given address
  def self.rating_area_for(address)
    self.find_rating_region(zip_code: address.zip, county_name: address.county).first.rating_region
  end

  class << self

    def rating_area_for(office_location)
      addr = office_location.address
      find_rating_area(zip_code: addr.zip, county_name: addr.county)
    end

    def find_counties_for(**attr)
      RateReference.where(attr).pluck(:county_name)
    end

    def find_rating_area(zip_code:, county_name:)
      region = self.where(zip_code: zip_code, county_name: county_name)
      raise "Multiple Regions Returned" if region.size > 1
      return nil if region.empty?
      region
    end

    def find_zip_codes_for(**attr)
      self.where(**attr).pluck(:zip_code)
    end
  end
end
