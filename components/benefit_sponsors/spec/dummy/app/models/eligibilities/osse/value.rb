# frozen_string_literal: true

module Eligibilities
  module Osse
    # Value model
    class Value
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :grant, class_name: "::Eligibilities::Osse::Grant"

      field :title, type: String
      field :description, type: String
      field :key, type: Symbol

      validates_presence_of :key
    end
  end
end
