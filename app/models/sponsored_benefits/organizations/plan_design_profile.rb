# Profile that supports Plan Design and Quoting functions
module SponsoredBenefits
  module Organizations
    class PlanDesignProfile < Profile

      field :profile_source, type: String, default: "broker_quote"
      field :contact_method, type: String, default: "Only Electronic communications"

    end
  end
end
