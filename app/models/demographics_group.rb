# frozen_string_literal: true

# Class representing a group of demographic information for a person.
# This class is embedded in any model that declares itself as 'demographicable'.
class DemographicsGroup
  include Mongoid::Document
  include Mongoid::Timestamps

  # @!attribute [rw] demographicable
  #   @return [Object] The object that this DemographicsGroup instance is associated with.
  #   This is a polymorphic association, so it can be any object that declares itself as 'demographicable'.
  embedded_in :demographicable, polymorphic: true

  # @!attribute [rw] alive_status
  #   @return [AliveStatus] The alive status of the person.
  #   This model is embedded in the DemographicsGroup model.
  #   It contains information about the person's status, such as whether they are alive or deceased.
  #   It does not implement DocumentVersion as this model has an evidence that has verification history.
  embeds_one :alive_status, class_name: "AliveStatus", cascade_callbacks: true

  # @note The birth_entries is not implemented yet.
  # embeds_many :birth_entries, class_name: 'BirthEntry', cascade_callbacks: true, validate: true

  # @note The gender_entries is not implemented yet.
  # embeds_many :gender_entries, class_name: 'GenderEntry', cascade_callbacks: true, validate: true
end
