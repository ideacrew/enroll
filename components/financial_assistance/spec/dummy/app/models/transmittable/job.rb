# frozen_string_literal: true

module Transmittable
  # A data model for a unitary transaction
  class Job
    include Mongoid::Document
    include Mongoid::Timestamps

    has_many :transmissions, class_name: 'Transmittable::Transmission'
    has_one :process_status, as: :statusable, class_name: 'Transmittable::ProcessStatus'
    accepts_nested_attributes_for :process_status
    has_many :transmittable_errors, as: :errorable, class_name: 'Transmittable::Error'
    accepts_nested_attributes_for :transmittable_errors

    field :job_id, type: String
    field :saga_id, type: String
    field :key, type: String
    field :title, type: String
    field :description, type: String
    field :publish_on, type: Date
    field :expire_on, type: DateTime
    field :started_at, type: DateTime
    field :ended_at, type: DateTime
    field :time_to_live, type: Integer
    field :allow_list, type: Array
    field :deny_list, type: Array
    field :message_id, type: String

    validates :message_id, uniqueness: true

    scope :latest, -> { order(created_at: :desc) }

    def generate_message_id
      loop do
        self.message_id = SecureRandom.uuid

        break unless Transmittable::Job.where(message_id: message_id).exists?
      end
      self.save
    end

    def error_messages
      return [] unless errors

      transmittable_errors&.map {|error| "#{error.key}: #{error.message}"}&.join(";")
    end
  end
end
