# frozen_string_literal: true

module Eligibilities
  class Determination
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :determinable, polymorphic: true
    embeds_many :subjects, class_name: "::Eligibilities::Subject", cascade_callbacks: true

    field :effective_date, type: Date

    accepts_nested_attributes_for :subjects
  end
end
