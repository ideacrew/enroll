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
    field :code_description, type: String
    field :raw_payload, type: String
  end
end