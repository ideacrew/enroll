# frozen_string_literal: true

# Class representing the alive status of a person.
# This class is embedded in the DemographicsGroup model.
# By default, a person is considered alive unless a source indicates otherwise.
# If the person is deceased, the date of death is stored in the date_of_death field.
class AliveStatus
  include Mongoid::Document
  include Mongoid::Timestamps

  # @!attribute [rw] demographics_group
  #   @return [DemographicsGroup] The associated demographics group.
  embedded_in :demographics_group, class_name: 'DemographicsGroup'

  # @!attribute [rw] is_deceased
  #   @return [Boolean] A flag indicating if the person is deceased. Default is false.
  field :is_deceased, type: Boolean, default: false

  # @!attribute [rw] date_of_death
  #   @return [Date, nil] The person's date of death, or nil if the person is not deceased.
  field :date_of_death, type: Date
end
