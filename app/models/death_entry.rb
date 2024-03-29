# frozen_string_literal: true

# Class representing a death entry for a person.
# This class is embedded in the PersonDemographicsGroup model.
class DeathEntry
  # DeathEntry class representing a death entry for a person.
  # This class includes the DocumentVersion module.
  #
  # @note The DocumentVersion module provides versioning capabilities to the DeathEntry class.
  # @todo Replace `include DocumentVersion` with `include Ideacrew::Mongoid::DocumentVersion` once the namespacing is finalized.
  include DocumentVersion

  # @!attribute [rw] person_demographics_group
  #   @return [PersonDemographicsGroup] The demographics group associated with the death entry.
  #   This is an instance of the PersonDemographicsGroup class.
  embedded_in :person_demographics_group, class_name: 'PersonDemographicsGroup'

  # @!attribute [rw] death_evidence
  #   @return [Eligibilities::Evidence] The evidence associated with the death entry.
  #   This is an instance of the Eligibilities::Evidence class.
  embeds_one :death_evidence, class_name: "::Eligibilities::Evidence", as: :evidenceable, cascade_callbacks: true

  # @!attribute [rw] is_deceased
  #   @return [Boolean] A flag indicating if the person is deceased. Default is false.
  field :is_deceased, type: Boolean, default: false

  # @!attribute [rw] date_of_death
  #   @return [Date] The date of death of the person.
  field :date_of_death, type: Date
end
