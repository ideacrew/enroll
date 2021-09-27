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

    delegate :primary_enrollee,
             :couple_enrollee,
             :couple_enrollee_one_dependent,
             :couple_enrollee_two_dependent,
             :couple_enrollee_many_dependent,
             :primary_enrollee_one_dependent,
             :primary_enrollee_two_dependent,
             :primary_enrollee_many_dependent,
             to: :qhp_premium_table,
             allow_nil: true

    delegate :rating_method, to: :product, allow_nil: true

    # Allowed values are 'Y', 'N', or nil for 'NA'
    field :tobacco_use, type: String

    validates_presence_of :age, :cost

    default_scope   ->{ order(:"age".asc) }

    def comparable_attrs
      [:age, :cost]
    end

    def product
      Rails.cache.fetch("rating_method_#{id}") do
        premium_table.product
      end
    end

    def qhp_premium_table
      return nil if product.age_based_rating?
      return nil if qhp_product.blank?

      qhp_product.qhp_premium_tables
                 .detect { |qpt| qpt.rate_area_id == premium_table.exchange_provided_code }
    end

    def qhp_product
      @qhp_product ||= ::Products::Qhp.where(standard_component_id: product.hios_base_id, active_year: product.active_year).first
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
