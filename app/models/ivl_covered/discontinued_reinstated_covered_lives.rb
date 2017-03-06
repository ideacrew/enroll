module IvlCovered
  class DiscontinuedReinstatedCoveredLives
    include Mongoid::Document
    store_in collection: "ivlCovered"
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
    
    field :cancel_one, type: String
    field :cancel_two, type: String
    field :cancel_three, type: String
    field :cancel_four, type: String

    field :cancel_five, type: String
    field :cancel_six, type: String
    field :cancel_seven, type: String
    field :cancel_eight, type: String

    field :cancel_nine, type: String
    field :cancel_ten, type: String
    field :cancel_eleven, type: String
    field :cancel_twelve, type: String

    field :terminations_one, type: String
    field :terminations_two, type: String
    field :terminations_three, type: String
    field :terminations_four, type: String

    field :terminations_five, type: String
    field :terminations_six, type: String
    field :terminations_seven, type: String
    field :terminations_eight, type: String

    field :terminations_nine, type: String
    field :terminations_ten, type: String
    field :terminations_eleven, type: String
    field :terminations_twelve, type: String

    field :reinstatements_one, type: String
    field :reinstatements_two, type: String
    field :reinstatements_three, type: String
    field :reinstatements_four, type: String

    field :reinstatements_five, type: String
    field :reinstatements_six, type: String
    field :reinstatements_seven, type: String
    field :reinstatements_eight, type: String

    field :reinstatements_nine, type: String
    field :reinstatements_ten, type: String
    field :reinstatements_eleven, type: String
    field :reinstatements_twelve, type: String

    default_scope ->{where(tile: "right_discontinued" )}

    # def self.discontinuedreinstatedlives_dashboard_stats
    #     discontinuedreinstatedlives =[ ]
    #     IvlCovered::DiscontinuedReinstatedCoveredLives.all.each do |dr|
    #         discontinuedreinstatedlives << dr if dr.month_one.present? && discontinuedreinstatedlives.size < 7 
    #     end
    #     discontinuedreinstatedlives
    # end
  end
end