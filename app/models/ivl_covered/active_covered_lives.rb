module IvlCovered
  class ActiveCoveredLives
    include Mongoid::Document
    store_in collection: "ivlCovered"

    field :tile , type: String
    field :count_jan_current, type: String 
    field :count_feb_current, type: Integer
    field :count_mar_current, type: Integer
    field :count_apr_current, type: Integer
    field :count_may_current, type: String
    field :count_jun_current, type: String
    field :count_jul_current, type: Integer
    field :count_aug_current, type: Integer
    field :count_sep_current, type: Integer
    field :count_oct_current, type: String
    field :count_nov_current, type: String
    field :count_dec_current, type: Integer

    field :count_jan_last, type: Integer
    field :count_feb_last, type: Integer
    field :count_mar_last, type: String
    field :count_apr_last, type: Integer
    field :count_may_last, type: Integer
    field :count_jun_last, type: String
    field :count_jul_last, type: Integer
    field :count_aug_last, type: Integer
    field :count_sep_last, type: String
    field :count_oct_last, type: Integer
    field :count_nov_last, type: Integer
    field :count_dec_last, type: String


    default_scope ->{where(tile: "right_active" )}
  end
end