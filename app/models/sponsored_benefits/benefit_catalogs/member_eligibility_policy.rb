# Product dependencies and eligibility rules applied to enrolling members
module SponsoredBenefits
  module BenefitCatalogs
    class MemberEligibilityPolicy

      # DC Individual
      # age-off 26, 65
      # catestrophic plans - enrollment group must be < 35
      ## See existing rules

      # DC SHOP 
      # must purchase health to purchase dental

      ## Congress member level
      # 'newly designated' special rules (bypass probation period)

      # CCA SHOP
      # access frozen plans if member enrolled in last year's mapped plan == true

      # GIC 
      # must purchase life to purchase health


    end
  end
end
