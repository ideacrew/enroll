module IvlCovered
  class AnnualCoveredLives
    include Mongoid::Document
    store_in collection: "ivlCovered"

    field :tile , type: String
    field :year, type: String
    field :covered_lives_total, type: String
    field :covered_lives_total_change, type: String
    field :covered_lives_new, type: String
    field :covered_lives_new_change, type: String
    field :covered_lives_terminations, type: String
    field :covered_lives_terminations_change, type: String
    field :covered_lives_cancellations, type: String
    field :covered_lives_cancellations_change, type: String

    default_scope ->{where(tile: "top" )}
  end
end