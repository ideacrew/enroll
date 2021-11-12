# frozen_string_literal: true

module Eligibilities
  module Families
    # Use Visitor Development Pattern to access Eligibilities and Eveidences
    # distributed across models
    class Snapshot
      include Mongoid::Document
      include Mongoid::Timestamps

      embeds_many :eligibilities, class_name: 'Eligibilities::Eligibility'

      # field :enrollment_period

      def accept(eligibility)
        eligibility.visit(self)
      end
    end
  end
end
