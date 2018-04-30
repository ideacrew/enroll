class ExtractCountyZipsForMa < Mongoid::Migration
  def self.up
    carrier_service_areas = connection["carrier_service_areas"]
    if carrier_service_areas
      say_with_time("Extract counties and zips using service areas as our source") do
        carrier_service_areas.find({}).aggregate([
          {"$match" => {serves_entire_state: false}},
          {"$group" => {_id: {zip_code: "$service_area_zipcode", county_name: "$county_name", county_code: "$county_code", active_year: "$active_year", state_code: "$state_code" }}},
          {"$project" => {zip_code: "$_id.zip_code", county_name: "$_id.county_name", state: "MA", county_code: "$_id.county_code", active_year: 2018, state_code: "$_id.state_code", _id: 0}},
          {"$out" => "benefit_markets_locations_county_zips"}
        ]).each 
      end
    end
  end

  def self.down
    ::BenefitMarkets::Locations::CountyZip.where.delete
  end
end
