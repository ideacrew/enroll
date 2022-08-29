# frozen_string_literal: true

module Eligibilities
  module Osse
    # Subject model
    class Subject
      include Mongoid::Document
      include Mongoid::Timestamps
      # include ::EventSource::Command
      # include Dry::Monads[:result, :do, :try]
      include GlobalID::Identification
      # include Eligibilities::Eventable

      embedded_in :grant, class_name: "::Eligibilities::Osse::Grant"

      field :title, type: String
      field :description, type: String
      field :key, type: String
      field :klass, type: String

      validates_presence_of :key, :klass
    end
  end
end
