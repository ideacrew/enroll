# frozen_string_literal: true

module Eligibilities
  #Store the history of each transaction a user or admin has performed on an evidence
  class VerificationHistory
    include Mongoid::Document
    include Mongoid::Timestamps
    include GlobalID::Identification

    embedded_in :evidence, class_name: '::Eligibilities::Evidence'

    field :action, type: String
    field :modifier, type: String
    field :update_reason, type: String
    field :updated_by, type: String
    field :is_satisfied, type: Boolean
    field :verification_outstanding, type: Boolean
    field :due_on, type: Date
    field :aasm_state, type: String
    field :date_of_action, type: DateTime

    after_create :set_date_of_action

    private

    def set_date_of_action
      update_attributes!(date_of_action: DateTime.now) unless date_of_action.present?
    end
  end
end
