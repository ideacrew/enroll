class BenefitEligibilityElementGroup

  include Mongoid::Document
  include Mongoid::Timestamps

  INDIVIDUAL_MARKET_RELATIONSHIP_CATEGORY_KINDS = %w(
    self
    spouse
    domestic_partner
    child
    parent
    sibling
    ward
    guardian
    unrelated
    other_tax_dependent
    aunt_or_uncle
    nephew_or_niece
    grandchild
    grandparent
  )

end
