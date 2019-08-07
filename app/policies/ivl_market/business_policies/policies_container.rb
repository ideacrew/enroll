# frozen_string_literal: true

module IvlMarket
  module BusinessPolicies
    class PoliciesContainer
      extend Dry::Container::Mixin

      register "aptc_policy_rules" do
        IvlMarket::BusinessPolicies::AptcPolicyRules.new
      end
    end
    IvlInjector = Dry::AutoInject(PoliciesContainer)
  end
end




