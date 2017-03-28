module IvlCovered
  class CoveredLivesMonth
    include Mongoid::Document
    store_in collection: "ivlCovered"

    field :tile , type: String
    field :selected_jan, type: Integer
    field :selected_feb, type: Integer
    field :selected_mar, type: Integer
    field :selected_apr, type: Integer

    field :selected_may, type: Integer
    field :selected_jun, type: Integer
    field :selected_jul, type: Integer
    field :selected_aug, type: Integer

    field :selected_sep, type: Integer
    field :selected_oct, type: Integer
    field :selected_nov, type: Integer
    field :selected_dec, type: Integer


    field :effectuated_jan, type: Integer
    field :effectuated_feb, type: Integer
    field :effectuated_mar, type: Integer
    field :effectuated_apr, type: Integer

    field :effectuated_may, type: Integer
    field :effectuated_jun, type: Integer
    field :effectuated_jul, type: Integer
    field :effectuated_aug, type: Integer

    field :effectuated_sep, type: Integer
    field :effectuated_oct, type: Integer
    field :effectuated_nov, type: Integer
    field :effectuated_dec, type: Integer

    field :effectuation_share_jan, type: Integer
    field :effectuation_share_feb, type: Integer
    field :effectuation_share_mar, type: Integer
    field :effectuation_share_apr, type: Integer

    field :effectuation_share_may, type: Integer
    field :effectuation_share_jun, type: Integer
    field :effectuation_share_jul, type: Integer
    field :effectuation_share_aug, type: Integer

    field :effectuation_share_sep, type: Integer
    field :effectuation_share_oct, type: Integer
    field :effectuation_share_nov, type: Integer
    field :effectuation_share_dec, type: Integer

    field :paying_jan, type: Integer
    field :paying_feb, type: Integer
    field :paying_mar, type: Integer
    field :paying_apr, type: Integer

    field :paying_may, type: Integer
    field :paying_jun, type: Integer
    field :paying_jul, type: Integer
    field :paying_aug, type: Integer

    field :paying_sep, type: Integer
    field :paying_oct, type: Integer
    field :paying_nov, type: Integer
    field :paying_dec, type: Integer

    field :terminated_jan, type: Integer
    field :terminated_feb, type: Integer
    field :terminated_mar, type: Integer
    field :terminated_apr, type: Integer

    field :terminated_may, type: Integer
    field :terminated_jun, type: Integer
    field :terminated_jul, type: Integer
    field :terminated_aug, type: Integer

    field :terminated_sep, type: Integer
    field :terminated_oct, type: Integer
    field :terminated_nov, type: Integer
    field :terminated_dec, type: Integer

    field :canceled_jan, type: Integer
    field :canceled_feb, type: Integer
    field :canceled_mar, type: Integer
    field :canceled_apr, type: Integer

    field :canceled_may, type: Integer
    field :canceled_jun, type: Integer
    field :canceled_jul, type: Integer
    field :canceled_aug, type: Integer

    field :canceled_sep, type: Integer
    field :canceled_oct, type: Integer
    field :canceled_nov, type: Integer
    field :canceled_dec, type: Integer

    default_scope ->{where(tile: "right_effective_month" )}

  end
end