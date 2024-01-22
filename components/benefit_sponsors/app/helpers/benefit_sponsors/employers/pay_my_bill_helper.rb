# frozen_string_literal: true

module BenefitSponsors
  module Employers
    # Helper methods for the PayMyBillTab on Employers Billing page
    module PayMyBillHelper
      # Retrieves the name associated with the PO lock box address from the EnrollRegistry.
      # @return [String] The name corresponding to the PO lock box address.
      def po_lock_box_name
        EnrollRegistry[:po_lock_box_address].settings(:name).item
      end

      # Retrieves the number associated with the PO lock box address from the EnrollRegistry.
      # @return [String] The number corresponding to the PO lock box address.
      def po_lock_box_number
        EnrollRegistry[:po_lock_box_address].settings(:number).item
      end

      # Retrieves the state associated with the PO lock box address from the EnrollRegistry.
      # @return [String] The state corresponding to the PO lock box address.
      def po_lock_box_state
        EnrollRegistry[:po_lock_box_address].settings(:state).item
      end

      # Retrieves the city associated with the PO lock box address from the EnrollRegistry.
      # @return [String] The city corresponding to the PO lock box address.
      def po_lock_box_city
        EnrollRegistry[:po_lock_box_address].settings(:city).item
      end

      # Retrieves the zip_code associated with the PO lock box address from the EnrollRegistry.
      # @return [String] The zip_code corresponding to the PO lock box address.
      def po_lock_box_zip_code
        EnrollRegistry[:po_lock_box_address].settings(:zip_code).item
      end
    end
  end
end
