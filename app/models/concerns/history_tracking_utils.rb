# frozen_string_literal: true

# @module HistoryTrackingUtils
# This module provides utility methods for tracking the history of an object.
#
# @example Include the module in a class to add history tracking related fields, scopes and methods.
#   class MyClass
#     include HistoryTrackingUtils
#   end
module HistoryTrackingUtils
  extend ActiveSupport::Concern

  # @!parse include Mongoid::Document
  # This class includes Mongoid::Document, which provides the basic functionality for models using the Mongoid ODM.
  include Mongoid::Document

  # @!parse include Mongoid::Timestamps
  # This class includes Mongoid::Timestamps, which automatically manages `created_at` and `updated_at` fields for the document.
  include Mongoid::Timestamps

  included do
    # Below fields for tracking Histroy of a model.
    # Repeatable
    # Trackable
    # Embedded
    # Could be a mixin

    # @!attribute [rw] started_at
    #   @return [DateTime] The date and time when the lifecycle of the object started.
    field :started_at, type: DateTime

    # @!attribute [rw] ended_at
    #   @return [DateTime] The date and time when the lifecycle of the object ended.
    field :ended_at, type: DateTime

    # @!attribute [rw] status
    #   @return [String] The lifecycle state or status of the record.
    field :status, type: String

    # @!attribute [rw] event
    #   @return [Symbol] The event that changed the status of the object.
    field :event, type: Symbol

    # @!attribute [rw] changed_or_corrected
    #   @return [String] Indicates whether the data has been changed or corrected.
    #   This field is typically populated with the value 'changed',
    #   but in rare cases (such as developer intervention to correct data),
    #   it may be populated with the value 'corrected'.
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
  end
end

# TODO: Add YARD documentation for the class, fields, constants and methods.
#       Add required scopes for the fields.
#       Add any additional methods required for the class.
#       Add tests for the class and methods
