# frozen_string_literal: true

# Class representing the alive status of a person.
# This class is embedded in the DemographicsGroup model.
# By default, a person is considered alive unless a source indicates otherwise.
# If the person is deceased, the date of death is stored in the date_of_death field.
# This class does not implement DocumentVersion as it has an evidence that has verification history.
class AliveStatus
  include Mongoid::Document
  include Mongoid::Timestamps

  # @!attribute [rw] demographics_group
  #   @return [DemographicsGroup] The demographics group associated with the alive status.
  #   This is an instance of the DemographicsGroup class.
  embedded_in :demographics_group, class_name: 'DemographicsGroup'

  # @!attribute [rw] alive_evidence
  #   @return [Eligibilities::Evidence] The evidence associated with the alive status.
  #   This is an instance of the Eligibilities::Evidence class.
  embeds_one :alive_evidence, class_name: "::Eligibilities::Evidence", as: :evidenceable, cascade_callbacks: true

  # @!attribute [rw] is_deceased
  #   @return [Boolean] A flag indicating if the person is deceased. Default is false.
  field :is_deceased, type: Boolean, default: false

  # @!attribute [rw] date_of_death
  #   @return [Date] The date of death of the person.
  field :date_of_death, type: Date

  # @note The boolean return value of `alive_status.alive_evidence.is_satisfied` determines the alive status of the person.
  # If it returns true, the person is considered alive. If it returns false, the person is considered deceased.
end
