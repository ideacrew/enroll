module BenefitMarkets
  module RulesEngine
    class Policy

      def self.rules
        @rules ||= []
      end

      def self.rule(*args)
        rules
        add_rule(PolicyRule.new(*args))
      end

      def self.add_rule(rule)
        @rules << rule
      end

      def evaluate(context)
        self.class.rules.each do |rule|
         rule.execute(context)
        end
      end
    end
  end
end
