# frozen_string_literal: true

# Class representing a group of demographic information for an individual.
# This class is embedded in any model that declares itself as 'demographable'.
class DemographicsGroup
  include Mongoid::Document
  include Mongoid::Timestamps

  # @!attribute [rw] demographable
  #   @return [Object] The object that this DemographicsGroup instance is associated with.
  #   This is a polymorphic association, so it can be any object that declares itself as 'demographable'.
  embedded_in :demographable, polymorphic: true

  # @!attribute[rw] gender
  #   @return [String] The gender of the individual.
  field :gender, type: String

  # @!attribute [rw] ethnicities
  #   @return [Array<Ethnicity>] The ethnicities associated with this DemographicsGroup.
  embed_one :ethnicities, class_name: 'Ethnicity', cascade_callbacks: true, validate: true

  # @!attribute [rw] races
  #   @return [Array<Race>] The races associated with this DemographicsGroup.
  embed_one :races, class_name: 'Race', cascade_callbacks: true, validate: true

  # @!attribute [rw] alive_status
  #   @return [AliveStatus] The alive status of the individual.
  #   This model is embedded in the DemographicsGroup model.
  #   It contains information about the individual's status, such as whether they are alive or deceased.
  embeds_one :alive_status, class_name: "AliveStatus", cascade_callbacks: true

  # @note The birth_entries is not implemented yet.
  # embeds_many :birth_entries, class_name: 'BirthEntry', cascade_callbacks: true, validate: true
end
