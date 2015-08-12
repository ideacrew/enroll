class GeographicRatingArea
  include Mongoid::Document
  include Mongoid::Timestamps

  # Example: http://insuremekevin.com/california-navigator/covered-california-regions-plans/

  embedded_in :benefit_sponsorship

  field :name, type: String

  embeds_many :us_counties
  embeds_many :zip_codes

end
