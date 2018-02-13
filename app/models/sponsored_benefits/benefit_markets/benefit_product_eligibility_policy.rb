module SponsoredBenefits
  module BenefitMarkets
    class BenefitProductEligibilityPolicy
      include Mongoid::Document
      include Mongoid::Timestamps

      ## product dependencies and rules

      ## sponsor level
      # access frozen plans if number of members enrolled in last year's mapped plan > 0

      ## member level
      # access frozen plans if member enrolled in last year's mapped plan == true
      # must purchase health to purchase dental
      # must purchase life to purchase health
      # age-off 26, 65

      ## congress member level
      # 'newly designated' special rules (bypass probation period)


    end
  end
end
