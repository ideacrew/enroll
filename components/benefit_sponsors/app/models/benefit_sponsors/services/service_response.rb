module BenefitSponsors
  module Services
    class ServiceResponse

      attr_reader :output

      def initialize(output)
        @output = output
      end

      def success?
        true
      end

      def failure?
        false
      end
    end
  end
end