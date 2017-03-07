module IvlCovered
  class TotalAccounts
    include Mongoid::Document
    store_in collection: "ivlCovered"

    field :tile, type: String
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
    
    field :account_one, type: String
    field :account_two, type: String
    field :account_three, type: String
    field :account_four, type: String

    field :account_five, type: String
    field :account_six, type: String
    field :account_seven, type: String
    field :account_eight, type: String

    field :account_nine, type: String
    field :account_ten, type: String
    field :account_eleven, type: String
    field :account_twelve, type: String

    field :enrolled_one, type: String
    field :enrolled_two, type: String
    field :enrolled_three, type: String
    field :enrolled_four, type: String

    field :enrolled_five, type: String
    field :enrolled_six, type: String
    field :enrolled_seven, type: String
    field :enrolled_eight, type: String

    field :enrolled_nine, type: String
    field :enrolled_ten, type: String
    field :enrolled_eleven, type: String
    field :enrolled_twelve, type: String
    
    default_scope ->{where(tile: "right_new_accounts" )}
  end
end