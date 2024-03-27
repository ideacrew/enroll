# frozen_string_literal: true

# @module HistoryTrackingUtils
# This module provides utility methods for tracking the history of an object.
#
# @example Include the module in a class to add history tracking related fields, scopes and methods.
#   class MyClass
#     include HistoryTrackingUtils
#   end

Action Items:
  1. Rename HistoryTrackingUtils to DocumentVersion
  2. Make Demographics as embeds_one instead of embeds_many.
  3. Make associations of children of Demographics from one to many.
  4. Add Domain Model named DocumentVersion
  5. Move scope to the collection level in the DocumentVersion module.
  6. We should have a mixin for the collection level. For Example: to fetch the latest instance of an ethnicity by using a scope. Do we need this?
  # 7. Add VERSION_SOURCE_TYPES to all the child models.
  # 8. Add a validation for VERSION_SOURCE_TYPES.
  9. Update the association, class names of Demographics to person_demographics_group.
  # 10. Encorporate Visitor pattern for source. ?

module DocumentVersion
  extend ActiveSupport::Concern

  # @!parse include Mongoid::Document
  # This class includes Mongoid::Document, which provides the basic functionality for models using the Mongoid ODM.
  include Mongoid::Document

  # @!parse include Mongoid::Timestamps
  # This class includes Mongoid::Timestamps, which automatically manages `created_at` and `updated_at` fields for the document.
  include Mongoid::Timestamps

  included do
    # @!attribute [rw] started_at
    #   @return [DateTime] The date and time when the lifecycle of the object started.
    field :started_at, type: DateTime

    # @!attribute [rw] ended_at
    #   @return [DateTime] The date and time when the lifecycle of the object ended.
    field :ended_at, type: DateTime

    # @!attribute [rw] status
    #   @return [Symbol] The lifecycle state or status of the record.
    field :status, type: Symbol

    # @!attribute [rw] is_active
    #   @return [Boolean] Indicates whether the object is active or not.
    #   This field can used to determine if there are more than one active objects for the same person.
    field :is_active, type: Boolean

    # GID. Used for Visitor Pattern.
    field :subject, type: URI? # url or uri

    # @!attribute [rw] event
    #   @return [Symbol] The event that changed the status of the object.
    field :event, type: Symbol

    # @!attribute [rw] changed_or_corrected
    #   @return [Symbol] Indicates whether the data has been changed or corrected.
    #   This field is typically populated with the value 'changed',
    #   but in rare cases (such as developer intervention to correct data),
    #   it may be populated with the value 'corrected'.
    field :changed_or_corrected, type: Symbol
    # SSN and DOB are the ones that are most likely to be corrected and not changed.
    # Date of Death could be both changed and corrected.

    # @!attribute [rw] sequence_id
    #   @return [Integer] A sequence number for each instance of the object.
    #   This can be used to construct the sequence of events for this particular object
    #   for history tracking reporting.
    #   Multiple people can have demopgraphics of sequence_id `1` but they are different objects.
    field :sequence_id, type: Integer

    # @!attribute [rw] reason
    #   @return [Symbol] The cause for creating a new object.
    #   This field is used to populate from a standard reasons list.
    #   'User Create', 'User Update', 'System Create', 'System Update'
    field :reason, type: String

    # @!attribute [rw] comment
    #   @return [String] Any additional information that is relevant to the system internally.
    #   This field could be used to add free text.
    field :comment, type: String

    # This needs to be at the collection/class level.
    # Scopes
    scope :latest, -> { order(created_at: :desc) }
  end
end
