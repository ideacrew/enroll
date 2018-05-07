module BenefitMarkets
  module RulesEngine
    class PolicyExecutionContext
      def initialize(**kwargs)
        @context_values = {}
        kwargs.each_pair do |k, v|
          @context_values[k.to_sym] = v
        end
        @context_errors = []
      end

      def get(kw)
        @context_values[kw]
      end

      def provided_values
        @context_values.keys
      end

      def fail!
      end

      def add_error(context, error)
        @context_errors << {context => error}
      end

    end
  end
end
