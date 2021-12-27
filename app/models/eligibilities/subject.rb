# frozen_string_literal: true

module Eligibilities
  class Subject
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :determination, class_name: "::Eligibilities::Determination"
    embeds_many :eligibility_states, class_name: "::Eligibilities::EligibilityState", cascade_callbacks: true

    field :gid, type: String
    field :first_name, type: String
    field :last_name, type: String
    field :is_primary, type: Boolean

    accepts_nested_attributes_for :eligibility_states

  end
end
