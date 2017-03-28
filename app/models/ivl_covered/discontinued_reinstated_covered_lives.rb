module IvlCovered
  class DiscontinuedReinstatedCoveredLives
    include Mongoid::Document
    store_in collection: "ivlCovered"
    field :tile , type: String
    field :cancel_jan, type: String
    field :cancel_feb, type: String
    field :cancel_mar, type: String
    field :cancel_apr, type: String

    field :cancel_may, type: String
    field :cancel_jun, type: String
    field :cancel_jul, type: String
    field :cancel_aug, type: String

    field :cancel_sep, type: String
    field :cancel_oct, type: String
    field :cancel_nov, type: String
    field :cancel_dec, type: String
    
    field :term_jan, type: String
    field :term_feb, type: String
    field :term_mar, type: String
    field :term_apr, type: String

    field :term_may, type: String
    field :term_jun, type: String
    field :term_jul, type: String
    field :term_aug, type: String

    field :term_sep, type: String
    field :term_oct, type: String
    field :term_nov, type: String
    field :term_dec, type: String

    field :reinstate_jan, type: String
    field :reinstate_feb, type: String
    field :reinstate_mar, type: String
    field :reinstate_apr, type: String

    field :reinstate_may, type: String
    field :reinstate_jun, type: String
    field :reinstate_jul, type: String
    field :reinstate_aug, type: String

    field :reinstate_sep, type: String
    field :reinstate_oct, type: String
    field :reinstate_nov, type: String
    field :reinstate_dec, type: String

    default_scope ->{where(tile: "right_discontinued" )}
  end
end