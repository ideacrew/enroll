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
  end
end

    # [
    #   {
    #     key: 'aptc_grant',
    #     value: 500.00,
    #     members: [ "Subject_gid1", 'Subject_gid2']
    #     start_on: date
    #   },
    #   {
    #     key: 'aptc_grant',
    #     value: 300.00,
    #     members: [ "Subject_gid3", 'Subject_gid4']
    #     end_on: date
    #    }
    # ]