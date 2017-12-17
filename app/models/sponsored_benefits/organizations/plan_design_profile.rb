# Profile that supports Plan Design and Quoting functions
module SponsoredBenefits
  module Organizations
    class PlanDesignProfile < Profile

      field :profile_source, type: String, default: "self_serve"
      field :contact_method, type: String, default: "Only Electronic communications"
      field :registered_on, type: Date, default: ->{ TimeKeeper.date_of_record }
      field :xml_transmitted_timestamp, type: DateTime

    end
  end
end
