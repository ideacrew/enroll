module IvlCovered
  class SepType
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
    
    field :lost_coverage_one, type: String
    field :lost_coverage_two, type: String
    field :lost_coverage_three, type: String
    field :lost_coverage_four, type: String

    field :lost_coverage_five, type: String
    field :lost_coverage_six, type: String
    field :lost_coverage_seven, type: String
    field :lost_coverage_eight, type: String

    field :lost_coverage_nine, type: String
    field :lost_coverage_ten, type: String
    field :lost_coverage_eleven, type: String
    field :lost_coverage_twelve, type: String

    field :lost_coverage_total, type: String
    field :lost_coverage_share, type: String

    field :birth_one, type: String
    field :birth_two, type: String
    field :birth_three, type: String
    field :birth_four, type: String

    field :birth_five, type: String
    field :birth_six, type: String
    field :birth_seven, type: String
    field :birth_eight, type: String

    field :birth_nine, type: String
    field :birth_ten, type: String
    field :birth_eleven, type: String
    field :birth_twelve, type: String

    field :birth_total, type: String
    field :birth_share, type: String

    field :citizenship_one, type: String
    field :citizenship_two, type: String
    field :citizenship_three, type: String
    field :citizenship_four, type: String

    field :citizenship_five, type: String
    field :citizenship_six, type: String
    field :citizenship_seven, type: String
    field :citizenship_eight, type: String

    field :citizenship_nine, type: String
    field :citizenship_ten, type: String
    field :citizenship_eleven, type: String
    field :citizenship_twelve, type: String

    field :citizenship_total, type: String
    field :citizenship_share, type: String

    field :relocation_one, type: String
    field :relocation_two, type: String
    field :relocation_three, type: String
    field :relocation_four, type: String

    field :relocation_five, type: String
    field :relocation_six, type: String
    field :relocation_seven, type: String
    field :relocation_eight, type: String

    field :relocation_nine, type: String
    field :relocation_ten, type: String
    field :relocation_eleven, type: String
    field :relocation_twelve, type: String

    field :relocation_total, type: String
    field :relocation_share, type: String

    field :other_one, type: String
    field :other_two, type: String
    field :other_three, type: String
    field :other_four, type: String

    field :other_five, type: String
    field :other_six, type: String
    field :other_seven, type: String
    field :other_eight, type: String

    field :other_nine, type: String
    field :other_ten, type: String
    field :other_eleven, type: String
    field :other_twelve, type: String

    field :other_total, type: String
    field :other_share, type: String

    field :total_one, type: String
    field :total_two, type: String
    field :total_three, type: String
    field :total_four, type: String

    field :total_five, type: String
    field :total_six, type: String
    field :total_seven, type: String
    field :total_eight, type: String

    field :total_nine, type: String
    field :total_ten, type: String
    field :total_eleven, type: String
    field :total_twelve, type: String

    field :total_total, type: String
    field :total_share, type: String

    default_scope ->{where(tile: "right_sep_type" )}
  end
end