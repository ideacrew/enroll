class RateReference
  include Mongoid::Document
  field :zip_code, type: String
  field :county_name, type: String
  field :rating_region, type: String
  field :zip_code_in_multiple_counties, type: Boolean, default: false

  validates_presence_of :zip_code, :county_name, :rating_region, :zip_code_in_multiple_counties
  validates_uniqueness_of :zip_code, :scope => [:county_name]

  class << self
    def find_rating_region(zip_code:, county_name:)
      region = self.where(zip_code: zip_code, county_name: county_name)
      raise "Multiple Regions Returned" if region.size > 1
      return nil if region.empty?
      region
    end

    def find_zip_codes_for_county(county_name:)
      self.where(county_name: county_name).pluck(:zip_code)
    end
  end
end
