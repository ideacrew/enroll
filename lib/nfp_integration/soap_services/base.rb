module NfpIntegration
  module SoapServices
    module Base

      def get_element_text(value)
        text = value.try(:first).try(:text)
        text.nil? ? "" : text.strip
      end

      def parse_statement_summary(response)
        past_due = get_element_text(response.xpath("//PastDue"))
        previous_balance = get_element_text(response.xpath("//PreviousBalance"))
        new_charges = get_element_text(response.xpath("//NewCharges"))
        adjustments = get_element_text(response.xpath("//Adjustments"))
        payments = get_element_text(response.xpath("//Payments"))
        total_due = get_element_text(response.xpath("//TotalDue"))
        return past_due, previous_balance, new_charges, adjustments, payments, total_due
      end

      def get_most_recent_payment_date(response)
        # assumes payload response lists elements in order of most recent to latest
        # Should we write a helper to extract the latest payment date by searching through all of them??

        date = get_element_text(response.xpath("//DateReceived"))
        unless (date.blank?)
          formatted_date = DateTime.parse(date).to_date.to_s
        end
      end

    end
  end
end
