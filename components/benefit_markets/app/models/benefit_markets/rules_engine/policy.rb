module BenefitMarkets
  class RulesEngine::Policy
    extend ActiveSupport::Concern

    def initialize(rules = [])
      @rules = rules
    end

    def add_rule(new_rule)
      @rules << new_rule
    end

    def process_rules
      collection.each do |rule|
        @rules.sort_by(&:priority).each do |rule|
          rule.run(rule)
        end
        rule.valid!
      end
    end

  end
end
