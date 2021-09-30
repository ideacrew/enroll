# frozen_string_literal: true

module Products
  class QhpPremiumTable
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :qhp, class_name: "Products::Qhp"

    field :rate_area_id, type: String
    field :plan_id, type: String
    field :tobacco, type: String

    field :effective_date, type: Date
    field :expiration_date, type: Date

    field :age_number, type: Integer

    field :primary_enrollee, type: Float
    field :couple_enrollee, type: Float
    field :couple_enrollee_one_dependent, type: Float
    field :couple_enrollee_two_dependent, type: Float
    field :couple_enrollee_many_dependent, type: Float
    field :primary_enrollee_one_dependent, type: Float
    field :primary_enrollee_two_dependent, type: Float
    field :primary_enrollee_many_dependent, type: Float
    field :is_issuer_data, type: Float
    field :primary_enrollee_tobacco, type: Float

  end
end
