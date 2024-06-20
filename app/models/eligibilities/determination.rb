# frozen_string_literal: true

module Eligibilities
  # family determinaiton model
  class Determination
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :determinable, polymorphic: true
    embeds_many :subjects, class_name: "::Eligibilities::Subject", cascade_callbacks: true
    embeds_many :grants, class_name: "::Eligibilities::Grant", cascade_callbacks: true

    field :effective_date, type: Date
    field :outstanding_verification_status, type: String
    field :outstanding_verification_earliest_due_date, type: Date
    field :outstanding_verification_document_status, type: String

    accepts_nested_attributes_for :subjects, :grants

    # seliarizable_cv_hash for family determination including subjects
    # @return [Hash] hash of family determination
    # Used in family cv3 payload
    def serializable_cv_hash
      subjects_hash = subjects.collect do |subject|
        Hash[
          URI(subject.gid).to_s,
          subject.serializable_cv_hash
        ]
      end.reduce(:merge)

      {effective_date: effective_date,
       subjects: subjects_hash,
       outstanding_verification_status: outstanding_verification_status,
       outstanding_verification_earliest_due_date: outstanding_verification_earliest_due_date,
       outstanding_verification_document_status: outstanding_verification_document_status}.deep_symbolize_keys
    end
  end
end
