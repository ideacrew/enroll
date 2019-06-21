class CompositeRatingTier
  EMPLOYEE_ONLY = "employee_only".freeze
  EMPLOYEE_AND_SPOUSE = "employee_and_spouse".freeze
  EMPLOYEE_AND_ONE_OR_MORE_DEPENDENTS = "employee_and_one_or_more_dependents".freeze
  FAMILY = "family".freeze

  NAMES = [
    EMPLOYEE_ONLY,
    EMPLOYEE_AND_SPOUSE,
    EMPLOYEE_AND_ONE_OR_MORE_DEPENDENTS,
    FAMILY
  ].freeze

  VISIBLE_NAMES = [
    EMPLOYEE_ONLY,
    FAMILY
  ].freeze
end
