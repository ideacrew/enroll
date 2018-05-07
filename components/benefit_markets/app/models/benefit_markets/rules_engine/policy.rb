module BenefitMarkets
  module RulesEngine
    class Policy
      def self.rules
        @rules ||= []
      end

      def self.rule(*args)
        add_rule(Rule.new(*args))
      end

      def self.add_rule(rule)
        @rules << rule
        enda
      end

      def evaluate(context)
        self.class.rules.each do |rule|
         rule.run(context)
        end 
      end
    end
  end
end
