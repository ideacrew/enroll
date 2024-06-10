# frozen_string_literal: true

module Eligibilities
  # Subject
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

    def csr_by_year(year)
      eligibility_state = eligibility_states.where(eligibility_item_key: 'aptc_csr_credit').first
      grant = eligibility_state.grants.where(key: 'CsrAdjustmentGrant', assistance_year: year).first

      grant&.value
    end

    def person
      ::Person.find(person_id)
    end

    # seliarizable_cv_hash for subject including eligibility states
    # @return [Hash] hash of subject
    def serializable_cv_hash
      eligibility_states_hash = eligibility_states.collect do |eligibility_state|
        Hash[
          eligibility_state.eligibility_item_key,
          eligibility_state.serializable_cv_hash
        ]
      end.reduce(:merge)

      subject_attributes = attributes.slice('first_name', 'last_name', 'encrypted_ssn', 'hbx_id',
                                            'person_id', 'outstanding_verification_status', 'is_primary')
      subject_attributes[:dob] = dob
      subject_attributes[:eligibility_states] = eligibility_states_hash

      subject_attributes
    end
  end
end

