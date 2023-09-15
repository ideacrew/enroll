# frozen_string_literal: true

require "dry-container"

module Operations
  module Eligible
    # Container for Dependency Injection using dry-auto_inject
    class EligibilityContainer
      extend Dry::Container::Mixin

      register "eligibility_defaults" do
        EligibilityConfiguration.new
      end

      register "evidence_defaults" do
        EvidenceConfiguration.new
      end
    end
  end
end
