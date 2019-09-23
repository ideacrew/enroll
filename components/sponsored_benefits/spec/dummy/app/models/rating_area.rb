class RatingArea
  include Mongoid::Document
  include Config::AcaModelConcern

  field :zip_code, type: String
  field :county_name, type: String
  field :rating_area, type: String
  field :zip_code_in_multiple_counties, type: Boolean, default: false

  def self.rating_area_for(address, proposal_for = TimeKeeper.date_of_record.year)
    zip_code = address.zip
    county_name = address.county
    area = where(zip_code: zip_code, county_name: county_name, :active_years => proposal_for)
    raise "Multiple Rating Areas Returned" if area.size > 1
    return nil if area.empty?
    area.first.rating_area
  end
end
