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
    field :full_name, type: String
    field :is_primary, type: Boolean
    field :hbx_id, type: String
    field :person_id, type: String
    field :encrypted_ssn, type: String
    field :dob, type: Date
    field :outstanding_verification_status, type: String

    accepts_nested_attributes_for :eligibility_states

    before_save :add_full_name

    def add_full_name
      self.full_name = [first_name, last_name].join(' ')
    end
  end
end

