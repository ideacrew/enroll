# frozen_string_literal: true

module Eligibilities
  class Determination
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :determinable, polymorphic: true

    field :effective_date, type: Date
    field :outstanding_verification_status, type: String
    field :outstanding_verification_earliest_due_date, type: Date
    field :outstanding_verification_document_status, type: String
  end
end