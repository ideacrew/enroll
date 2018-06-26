module BenefitMarkets
  class Locations::RatingArea
    include Mongoid::Document
    include Mongoid::Timestamps

    field :active_year, type: Integer
    field :exchange_provided_code, type: String

    # The list of county-zip pairs covered by this rating area
    field :county_zip_ids, type: Array

    # This rating area may cover entire state(s), if it does,
    # specify which here.
    field :covered_states, type: Array

    validates_presence_of :active_year, allow_blank: false
    validates_presence_of :exchange_provided_code, allow_nil: false

    validate :location_specified

    index({county_zip_ids: 1})
    index({covered_state_codes: 1})

    def location_specified
      if county_zip_ids.blank? && covered_states.blank?
        errors.add(:base, "a location covered by the rating area must be specified")
      end
      true
    end

    def self.rating_area_for(address, during: TimeKeeper.date_of_record)
      county_zip_ids = ::BenefitMarkets::Locations::CountyZip.where(
        :zip => address.zip,
        :county_name => address.county.titlecase,
        :state => address.state.upcase
      ).map(&:id)
      
      # TODO FIX
      # raise "Multiple Rating Areas Returned" if area.count > 1
      
      self.where(
        "active_year" => during.year,
        "$or" => [
          {"county_zip_ids" => { "$in" => county_zip_ids }},
          {"covered_states" => address.state.upcase}
        ]
      ).first
    end
  end
end
