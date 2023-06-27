# frozen_string_literal: true

module Eligibilities
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

    def default_earliest_verification_due_date
      if outstanding_verification_status == 'outstanding'
        verification_document_due = EnrollRegistry[:verification_document_due_in_days].item
        outstanding_verification_earliest_due_date || TimeKeeper.date_of_record + verification_document_due.days
      end
    end
  end
end
