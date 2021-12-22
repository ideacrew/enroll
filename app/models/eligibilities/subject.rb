module Eligibilities
  class Subject
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :determination, class_name: "::Eligibilities::Determination"
    embeds_many :eligibility_states, class_name: "::Eligibilities::EligibilityState"

    field :gid, type: String
    field :first_name, type: String
    field :last_Name, type: String
    field :is_primary, type: Boolean
  end
end
