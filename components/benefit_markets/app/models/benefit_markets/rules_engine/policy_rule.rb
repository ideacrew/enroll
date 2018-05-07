module BenefitMarkets
  module RulesEngine
    class PolicyRule
      class RequiredInformationMissingError < ArgumentError
        attr_reader :missing_arguements
        def initialize(err, missing_args = [])
          super(err)
          @missing_arguments = missing_args
        end
      end

      attr_reader :requires
      attr_reader :test
      attr_reader :success
      attr_reader :failure
      attr_reader :name

      NO_OP = lambda {|o| true }

      def initialize(name, 
                      requires: [],
                      validate: NO_OP,
                      failure: NO_OP,
                      success: NO_OP
                    )

        @name = name
        @failure = failure
        @success = success
        @validate = validate
        @requires = requires
      end

      def execute(context)
        missing_keys = @requires - context.provided_values
        if missing_keys.any?
          raise RequiredInformationMissingError.new("required keys missing", missing_keys)
        end
        if validate.call(context)
          success.call(context)
        else
          failure.call(context)
        end
      end
    end
  end
end
