class RateReference
  include Mongoid::Document
 
  field :zip_code, type: String
  field :county, type: String
  field :rating_region, type: String
  field :multiple_counties, type: Boolean, default: false
 
   validates_presence_of :zip_code, :county, :rating_region, :multiple_counties

   class << self
   def find_rating_region(zip, county)
     record = self.where(zip_code: zip, county: county).first
     record.present? ? record : nil
   end
   end
 end