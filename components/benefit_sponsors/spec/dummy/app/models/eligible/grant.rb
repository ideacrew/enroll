# frozen_string_literal: true

module Eligible
  # Grant model
  class Grant
    include Mongoid::Document
    include Mongoid::Timestamps

    field :key, type: Symbol
    field :title, type: String
    field :description, type: String
    field :current_state, type: Symbol

    embeds_one :value,
               class_name: '::Eligible::Value',
               cascade_callbacks: true

    validates_presence_of :title, :key
  end
end