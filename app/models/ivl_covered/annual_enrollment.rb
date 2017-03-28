  module IvlCovered
  class AnnualEnrollment
    include Mongoid::Document
    store_in collection: "ivlCovered"

    field :tile , type: String
    field :auto_renewals_select, type: Integer
    field :auto_renewals_effectuate, type: Integer
    field :auto_renewals_paying, type: Integer
    field :auto_renewals_pay_share, type: String
    field :active_renewals_select, type: Integer
    field :active_renewals_effectuate, type: Integer
    field :active_renewals_paying, type: Integer
    field :active_renewals_pay_share, type: String
    field :new_customers_select, type: Integer
    field :new_customers_effectuate, type: Integer
    field :new_customers_paying, type: Integer
    field :new_customers_pay_share, type: String
    field :sep_select, type: Integer
    field :sep_effectuate, type: Integer
    field :sep_paying, type: Integer
    field :sep_pay_share, type: String

    default_scope ->{where(tile: "left_enrollment" )}
  end
end