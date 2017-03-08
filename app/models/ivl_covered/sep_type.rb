module IvlCovered
  class SepType
    include Mongoid::Document
    store_in collection: "ivlCovered"

    field :tile , type: String
    field :month_one, type: Integer
    field :month_two, type: Integer
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
    
    field :lost_coverage_one, type: Integer
    field :lost_coverage_two, type: Integer
    field :lost_coverage_three, type: Integer
    field :lost_coverage_four, type: Integer

    field :lost_coverage_five, type: Integer
    field :lost_coverage_six, type: Integer
    field :lost_coverage_seven, type: Integer
    field :lost_coverage_eight, type: Integer

    field :lost_coverage_nine, type: Integer
    field :lost_coverage_ten, type: Integer
    field :lost_coverage_eleven, type: Integer
    field :lost_coverage_twelve, type: String

    field :lost_coverage_total, type: Integer
    field :lost_coverage_share, type: String

    field :birth_one, type: Integer
    field :birth_two, type: Integer
    field :birth_three, type: Integer
    field :birth_four, type: Integer

    field :birth_five, type: Integer
    field :birth_six, type: Integer
    field :birth_seven, type: Integer
    field :birth_eight, type: Integer

    field :birth_nine, type: Integer
    field :birth_ten, type: Integer
    field :birth_eleven, type: Integer
    field :birth_twelve, type: Integer

    field :birth_total, type: Integer
    field :birth_share, type: String

    field :citizenship_one, type: Integer
    field :citizenship_two, type: Integer
    field :citizenship_three, type: Integer
    field :citizenship_four, type: Integer

    field :citizenship_five, type: Integer
    field :citizenship_six, type: Integer
    field :citizenship_seven, type: Integer
    field :citizenship_eight, type: Integer

    field :citizenship_nine, type: Integer
    field :citizenship_ten, type: Integer
    field :citizenship_eleven, type: Integer
    field :citizenship_twelve, type: Integer

    field :citizenship_total, type: Integer
    field :citizenship_share, type: String

    field :relocation_one, type: Integer
    field :relocation_two, type: Integer
    field :relocation_three, type: Integer
    field :relocation_four, type: Integer

    field :relocation_five, type: Integer
    field :relocation_six, type: Integer
    field :relocation_seven, type: Integer
    field :relocation_eight, type: Integer

    field :relocation_nine, type: Integer
    field :relocation_ten, type: Integer
    field :relocation_eleven, type: Integer
    field :relocation_twelve, type: Integer

    field :relocation_total, type: Integer
    field :relocation_share, type: String

    field :other_one, type: Integer
    field :other_two, type: Integer
    field :other_three, type: Integer
    field :other_four, type: Integer

    field :other_five, type: Integer
    field :other_six, type: Integer
    field :other_seven, type: Integer
    field :other_eight, type: Integer

    field :other_nine, type: Integer
    field :other_ten, type: Integer
    field :other_eleven, type: Integer
    field :other_twelve, type: Integer

    field :other_total, type: Integer
    field :other_share, type: String

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

    default_scope ->{where(tile: "right_sep_type" )}
  end
end