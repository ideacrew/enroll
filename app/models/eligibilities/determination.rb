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

    def determination_cv3_hash
      subjects_cv3 = subjects.collect do |subject|
        Hash[
          URI(subject.gid),
          subject.subject_cv3_hash
        ]
      end.reduce(:merge)

      {effective_date: effective_date,
       subjects: subjects_cv3,
       outstanding_verification_status: outstanding_verification_status,
       outstanding_verification_earliest_due_date: outstanding_verification_earliest_due_date,
       outstanding_verification_document_status: outstanding_verification_document_status}.deep_symbolize_keys
    end
  end
end
