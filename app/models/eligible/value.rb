# frozen_string_literal: true

module Eligible
  # Value model
  class Value
    include Mongoid::Document
    include Mongoid::Timestamps

    field :title, type: String
    field :description, type: String
    field :key, type: Symbol

    validates_presence_of :title, :key
  end
end
