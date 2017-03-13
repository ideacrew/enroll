  module IvlPolicie
  class PolicyAnnualEnrollmentType
    include Mongoid::Document
    store_in collection: "ivlPolicies"

    field :tile , type: String
    field :auto_renewals_count, type: Integer
    field :auto_renewals_share, type: String
    field :auto_renewals_yoy, type: String
    field :active_renewals_count, type: Integer
    field :active_renewals_share, type: String
    field :active_renewals_yoy, type: String
    field :new_customers_count, type: Integer
    field :new_customers_share, type: String
    field :new_customers_yoy, type: String
    field :sep_count, type: Integer
    field :sep_share, type: String
    field :sep_yoy, type: String

    default_scope ->{where(tile: "left_enrollment_type" )}
  end
end