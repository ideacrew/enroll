# frozen_string_literal: true

# Class representing a group of demographic information for a person.
# This class is embedded in any model that declares itself as 'demographable'.
class PersonDemographicsGroup
  include Mongoid::Document
  include Mongoid::Timestamps

  # @!attribute [rw] demographable
  #   @return [Object] The object that this PersonDemographicsGroup instance is associated with.
  #   This is a polymorphic association, so it can be any object that declares itself as 'demographable'.
  embedded_in :demographable, polymorphic: true

  # @!attribute [rw] ethnicities
  #   @return [Array<Ethnicity>] The ethnicities associated with this PersonDemographicsGroup.
  embeds_many :ethnicities, class_name: 'Ethnicity', cascade_callbacks: true, validate: true

  # @!attribute [rw] races
  #   @return [Array<Race>] The races associated with this PersonDemographicsGroup.
  embeds_many :races, class_name: 'Race', cascade_callbacks: true, validate: true

  # @!attribute [rw] alive_status
  #   @return [AliveStatus] The alive status of the person.
  #   This model is embedded in the PersonDemographicsGroup model.
  #   It contains information about the person's status, such as whether they are alive or deceased.
  #   It does not implement DocumentVersion as this model has an evidence that has verification history.
  embeds_one :alive_status, class_name: "AliveStatus", cascade_callbacks: true

  # @note The birth_entries is not implemented yet.
  # embeds_many :birth_entries, class_name: 'BirthEntry', cascade_callbacks: true, validate: true

  # @note The gender_entries is not implemented yet.
  # embeds_many :gender_entries, class_name: 'GenderEntry', cascade_callbacks: true, validate: true
end
