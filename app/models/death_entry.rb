# frozen_string_literal: true

class DeathEntry
  include Ideacrew::Mongoid::DocumentVersion

  field :is_deceased, type: Boolean, default: false
  field :date_of_death, type: Date

  embeds_one :death_evidence, class_name: "::Eligibilities::Evidence", as: :evidenceable, cascade_callbacks: true
end
