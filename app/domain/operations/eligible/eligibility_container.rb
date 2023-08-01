require "dry-container"

module Operations
  module Eligible
    class EligibilityContainer
      extend Dry::Container::Mixin

      register "eligibility_defaults" do
        EligibilityConfiguration
      end

      register "evidence_defaults" do
        EvidenceConfiguration
      end
    end
  end
end
