# frozen_string_literal: true

module Eligibilities
  module Osse
    # Eligibility model
    class Eligibility
      include Mongoid::Document
      include Mongoid::Timestamps
      # include ::EventSource::Command
      # include Dry::Monads[:result, :do, :try]
      # include GlobalID::Identification
      # include Eligibilities::Eventable

      # DUE_DATE_STATES = %w[review outstanding rejected].freeze

      embedded_in :eligible, polymorphic: true
  
      field :title, type: String
      field :description, type: String
      field :start_on, type: Date
      field :end_on, type: Date
      field :status, type: String
      # field :updated_by, type: String
      # field :update_reason, type: String
  
      embeds_many :subject, class_name: "::Eligibilities::Osse::Subject", cascade_callbacks: true
      embeds_many :evidences, class_name: "::Eligibilities::Osse::Subject", cascade_callbacks: true
      embeds_many :grants, class_name: "::Eligibilities::Osse::Subject", cascade_callbacks: true

      accepts_nested_attributes_for :evidences, :grants
  
      validates_presence_of :start_on  
     
    end
  end
end
