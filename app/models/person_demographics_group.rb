# frozen_string_literal: true

# @class Demographics
# This class represents a Demographics, which stores demographic information.
# It includes HistoryTrackingUtils for tracking the history of an object.
# It is embedded in a polymorphic association and can belong to any model that declares itself as 'demographable'.
# It embeds one Ethnicity and one Race.
class PersonDemographicGroup
  # # @!parse include HistoryTrackingUtils
  # # This class includes HistoryTrackingUtils, which provides utility methods for tracking the history of an object.
  # include HistoryTrackingUtils

  # @!attribute [rw] demographable
  #   @return [Object] The object that this Demographics instance is associated with.
  #   This is a polymorphic association, so it can be any object that declares itself as 'demographable'.
  embedded_in :demographable, polymorphic: true

  # @!attribute [rw] ethnicity
  #   @return [Ethnicity] The ethnicity of the individual.
  #   @!parse extend Mongoid::Association::Embedded::EmbedsOne
  embeds_many :ethnicity

  # @!attribute [rw] race
  #   @return [Race] The race of the individual.
  #   @!parse extend Mongoid::Association::Embedded::EmbedsOne
  embeds_many :races

  # embeds_many :dates_of_birth

  # embeds_many :date_of_birth_versions

  # BirthEntry
  embeds_many :birth_entries

  # DeathEntry
  embeds_many :death_entries


  # birth_reports

  # death_reports

  # embeds_many :dates_of_death
end
