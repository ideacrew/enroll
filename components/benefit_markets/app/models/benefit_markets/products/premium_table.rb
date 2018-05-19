## Product premium costs for a specified time period
# Effective periods:
#   DC & MA SHOP Health: Q1, Q2, Q3, Q4
#   DC Dental: annual
#   GIC Medicare: Jan-June, July-Dec
#   DC & MA IVL: annual

module BenefitMarkets
  class Products::PremiumTable
    include Mongoid::Document
    include Mongoid::Timestamps
    include Comparable

    embedded_in :product, class_name: "BenefitMarkets::Products::Product"

    field       :effective_period,  type: Range


    belongs_to  :rating_area,
                class_name: "BenefitMarkets::Locations::RatingArea"

    embeds_many :premium_tuples,
                class_name: "BenefitMarkets::Products::PremiumTuple"

    validates_presence_of :effective_period, :rating_area
    # validates_presence_of :premium_tuples, :allow_blank => false

    def comparable_attrs
      [:effective_period, :rating_area]
    end

    # Define Comparable operator
    # If instance attributes are the same, compare PremiumTuples
    def <=>(other)
      if comparable_attrs.all? { |attr| eval(attr.to_s) == eval("other.#{attr.to_s}") }
        if premium_tuples == other.premium_tuples
          0
        else
          premium_tuples <=> other.premium_tuples
        end
      else
        other.updated_at.blank? || (updated_at < other.updated_at) ? -1 : 1
      end
    end
  end
end
