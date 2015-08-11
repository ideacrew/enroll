class BenefitPackage
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :benefit_coverage_period

  ELIGIBLE_COVERAGE_RELATIONSHIP_KINDS = [
      :self,
      :spouse,
      :domestic_partner,
      :child_under_26,
      :disabled_child_26_and_over
    ]


# who's covered
# premium credits -- calculation
# benefit products offered


end
