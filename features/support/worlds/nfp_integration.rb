module NfpIntegration
  module SoapServices
    class Nfp
      def initialize(customer_id)
        @customer_id = customer_id
        return ""
      end

      def display_token
        ""
      end

      def parse_statement_summary(response)
        nil
      end

      def payment_history
        nil
      end

      def statement_summary
        nil
      end

      def get_most_recent_payment_date(response)
        nil
      end

    end
  end
end
