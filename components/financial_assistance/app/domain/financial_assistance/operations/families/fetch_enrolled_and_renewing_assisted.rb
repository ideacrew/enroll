# frozen_string_literal: true

# Operations::Families::FetchEnrolledAndRenewingAssisted.new.call({csr_list: ['02', '03', '04', '05', '06']})
# Operations::Families::FetchEnrolledAndRenewingAssisted.new.call({})
module FinancialAssistance
module Operations
  module Families
    # This operation fetches families with active health enrollment with APTC or CSR
    class FetchEnrolledAndRenewingAssisted
      include Dry::Monads[:result, :do]

      def call(params)
        csr_list = yield validate(params)
        families = yield fetch_families(csr_list)

        Success(families)
      end

      private

      def validate(params)
        return Success(params[:csr_list]) if params[:csr_list].present?

        Success(%w[02 03 04 05 06])
      end

      # returns only families that have active health enrollment with APTC or CSR
      def fetch_families(csr_list)
        families = Family.with_applied_aptc_or_csr_active_enrollments(csr_list)

        if families.present?
          Success(families)
        else
          Failure("No families found")
        end
      end
    end
  end
end
end