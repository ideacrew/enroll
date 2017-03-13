module IvlPolicie
  class PoliciesEnrollment
    include Mongoid::Document
    store_in collection: "ivlPolicies"

    field :tile , type: String
    field :month_one, type: String
    field :month_two, type: String
    field :month_three, type: String
    field :month_four, type: String

    field :month_five, type: String
    field :month_six, type: String
    field :month_seven, type: String
    field :month_eight, type: String

    field :month_nine, type: String
    field :month_ten, type: String
    field :month_eleven, type: String
    field :month_twelve, type: String
    
    field :auto_renew_one, type: Integer
    field :auto_renew_two, type: Integer
    field :auto_renew_three, type: Integer
    field :auto_renew_four, type: Integer

    field :auto_renew_five, type: Integer
    field :auto_renew_six, type: Integer
    field :auto_renew_seven, type: Integer
    field :auto_renew_eight, type: Integer

    field :auto_renew_nine, type: Integer
    field :auto_renew_ten, type: Integer
    field :auto_renew_eleven, type: Integer
    field :auto_renew_twelve, type: Integer

    field :auto_renew_total, type: Integer
    field :auto_renew_share, type: String

    field :active_renew_one, type: Integer
    field :active_renew_two, type: Integer
    field :active_renew_three, type: Integer
    field :active_renew_four, type: Integer

    field :active_renew_five, type: Integer
    field :active_renew_six, type: Integer
    field :active_renew_seven, type: Integer
    field :active_renew_eight, type: Integer

    field :active_renew_nine, type: Integer
    field :active_renew_ten, type: Integer
    field :active_renew_eleven, type: Integer
    field :active_renew_twelve, type: Integer

    field :active_renew_total, type: Integer
    field :active_renew_share, type: String

    field :newCustomer_one, type: Integer
    field :newCustomer_two, type: Integer
    field :newCustomer_three, type: Integer
    field :newCustomer_four, type: Integer

    field :newCustomer_five, type: Integer
    field :newCustomer_six, type: Integer
    field :newCustomer_seven, type: Integer
    field :newCustomer_eight, type: Integer

    field :newCustomer_nine, type: Integer
    field :newCustomer_ten, type: Integer
    field :newCustomer_eleven, type: Integer
    field :newCustomer_twelve, type: String

    field :newCustomer_total, type: Integer
    field :newCustomer_share, type: String

    field :sep_one, type: Integer
    field :sep_two, type: Integer
    field :sep_three, type: Integer
    field :sep_four, type: Integer

    field :sep_five, type: Integer
    field :sep_six, type: Integer
    field :sep_seven, type: Integer
    field :sep_eight, type: Integer

    field :sep_nine, type: Integer
    field :sep_ten, type: Integer
    field :sep_eleven, type: Integer
    field :sep_twelve, type: Integer

    field :sep_total, type: Integer
    field :sep_share, type: String

    field :total_one, type: Integer
    field :total_two, type: Integer
    field :total_three, type: Integer
    field :total_four, type: Integer

    field :total_five, type: Integer
    field :total_six, type: Integer
    field :total_seven, type: Integer
    field :total_eight, type: Integer

    field :total_nine, type: Integer
    field :total_ten, type: Integer
    field :total_eleven, type: Integer
    field :total_twelve, type: Integer

    field :total_total, type: Integer
    field :total_share, type: String

    default_scope ->{where(tile: "right_enrollment_type" )}

  end
end