# frozen_string_literal: true

# This module provides methods for tracking the transmittable reference of an object.
#
# @example Include the module in a class to add transmittable reference related fields.
#   class MyClass
#     include Transmittable::Reference
#   end
module Transmittable
  module Reference
    extend ActiveSupport::Concern

    included do
      # @!attribute [rw] saga_id
      #   @return [String] The saga ID associated with the transmittable saga ID.
      field :saga_id, type: String

      # @!attribute [rw] job_id
      #   @return [String] The job ID associated with the transmittable request/response of the job on the other application of the saga(associated with saga_id).
      field :job_id, type: String

      # @!attribute [rw] transmission_id
      #   @return [String] The transmission ID associated with the transmittable request/response of the job(associated with job_id).
      field :transmission_id, type: String

      # @!attribute [rw] transaction_id
      #   @return [String] The transaction ID associated with the transmittable request/response of the transmission(associated with transmission_id).
      field :transaction_id, type: String
    end
  end
end
