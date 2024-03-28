# frozen_string_literal: true

# @class Demographics
# This class represents a Demographics, which stores demographic information.
# It includes HistoryTrackingUtils for tracking the history of an object.
# It is embedded in a polymorphic association and can belong to any model that declares itself as 'demographable'.
# It embeds one Ethnicity and one Race.
class Demographics
  # @!parse include HistoryTrackingUtils
  # This class includes HistoryTrackingUtils, which provides utility methods for tracking the history of an object.
  include HistoryTrackingUtils

  # @!attribute [rw] demographable
  #   @return [Object] The object that this Demographics instance is associated with.
  #   This is a polymorphic association, so it can be any object that declares itself as 'demographable'.
  embedded_in :demographable, polymorphic: true

  # @!attribute [rw] gender
  #   @return [Gender] The gender of the individual.
  #   @!parse extend Mongoid::Association::Embedded::EmbedsOne
  embeds_one :gender

  # @!attribute [rw] ethnicity
  #   @return [Ethnicity] The ethnicity of the individual.
  #   @!parse extend Mongoid::Association::Embedded::EmbedsOne
  embeds_one :ethnicity

  # @!attribute [rw] race
  #   @return [Race] The race of the individual.
  #   @!parse extend Mongoid::Association::Embedded::EmbedsOne
  embeds_one :race
end
