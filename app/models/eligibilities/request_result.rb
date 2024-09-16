# frozen_string_literal: true

module Eligibilities
  #store all the results we received from fdsh HUB
  class RequestResult
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :evidence, class_name: '::Eligibilities::Evidence'

    field :result, type: String
    field :source, type: String
    field :source_transaction_id, type: String
    field :code, type: String
    field :code_description, type: Date
    field :raw_payload, type: String
    field :date_of_action, type: DateTime
    field :action, type: String

    before_create :set_date_of_action, unless: -> { date_of_action.present? }

    private

    def set_date_of_action
      write_attribute(:date_of_action, DateTime.now)
    end
  end
end