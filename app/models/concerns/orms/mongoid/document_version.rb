# frozen_string_literal: true

# @module Orms::Mongoid::DocumentVersion
# This module provides functionality for tracking the version history of a document.
#
# @example To add version tracking capabilities to a class, include the Orms::Mongoid::DocumentVersion module.
#   class MyClass
#     include Orms::Mongoid::DocumentVersion
#   end
module Orms
  module Mongoid
    module DocumentVersion
      extend ActiveSupport::Concern

      # @!parse include Mongoid::Document
      # This class includes Mongoid::Document, which provides the basic functionality for models using the Mongoid ODM.
      include ::Mongoid::Document

      # @!parse include Mongoid::Timestamps
      # This class includes Mongoid::Timestamps, which automatically manages `created_at` and `updated_at` fields for the document.
      include ::Mongoid::Timestamps

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
        #   @return [Mongoid::Boolean] Indicates whether the object is active or not.
        #   This field can used to determine if there are more than one active objects for the same person.
        field :is_active, type: ::Mongoid::Boolean

        # @!attribute [rw] subject
        #   @return [String] The globalid of the source object this document version is associated with.
        #   This field is used to find/track the source object.
        #   It is a global identifier.
        #   This field could be potentially used for Visitor pattern implementation to find the source object.
        field :subject, type: String

        # @!attribute [rw] event
        #   @return [Symbol] The event that changed the status of the object.
        field :event, type: Symbol

        # @!attribute [rw] changed_or_corrected
        #   @return [Symbol] Indicates whether the data has been changed or corrected.
        #   This field is typically populated with the value 'changed',
        #   but in rare cases (such as developer intervention to correct data),
        #   it may be populated with the value 'corrected'.
        # @note SSN and DOB are the ones that are most likely to be corrected and not changed.
        # Date of Death could be both changed and corrected.
        field :changed_or_corrected, type: Symbol

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

        # Scopes
        scope :latest, -> { order(created_at: :desc) }
        scope :earliest, -> { order(created_at: :asc) }
      end
    end
  end
end
