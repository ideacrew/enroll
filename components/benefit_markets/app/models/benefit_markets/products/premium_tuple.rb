module BenefitMarkets
  class Products::PremiumTuple
    include Mongoid::Document
    include Mongoid::Timestamps

    TOBACCO_USE_VALUES = ['Y', 'N', 'nil', 'NA'].freeze

    embedded_in :premium_table,
                class_name: "BenefitMarkets::Products::PremiumTable"

    field :age,   type: Integer
    field :cost,  type: Float
    field :tobacco_cost, type: Float # if ::EnrollRegistry.feature_enabled?(:tobacco_cost)

    # Allowed values are 'Y', 'N', or nil for 'NA'
    field :tobacco_use, type: String

    validates_presence_of :age, :cost

    default_scope   ->{ order(:"age".asc) }

    def comparable_attrs
      [:age, :cost]
    end

    def couple_enrollee
      20
    end

    def couple_enrollee_one_dependent
      30
    end

    def couple_enrollee_two_dependent
      40
    end

    def couple_enrollee_many_dependent
      60
    end

    def primary_enrollee_one_dependent
      10
    end

    def primary_enrollee_two_dependent
      20
    end

    def primary_enrollee_many_dependent
      30
    end

    # Define Comparable operator
    # If instance attributes are the same, compare PremiumTuples
    def <=>(other)
      if comparable_attrs.all? { |attr| send(attr) == other.send(attr) }
        0
      else
        other.updated_at.blank? || (updated_at < other.updated_at) ? -1 : 1
      end
    end

    def tobacco_use_value
      tobacco_use.blank? ? "NA" : tobacco_use
    end
  end
end
