# frozen_string_literal: true

module BenefitSponsors
  module BenefitSponsorships
    class FinancialTransaction
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :benefit_sponsorship_account,
                  class_name: "::BenefitSponsors::BenefitSponsorships:BenefitSponsorshipAccount",
                  inverse_of: :financial_transactions


      METHOD_KINDS = ['ach', 'credit_card', 'check'].freeze

      # Payment status
      field :paid_on, type: Date
      field :amount, type: Money

      # Payment instrument
      field :method_kind, type: String

      # For Payment by check

      # Confirmation ID or similar
      field :reference_id, type: String

      # Network reference to the payment document
      field :document_uri, type: String

      validates_presence_of :paid_on, :amount, :method_kind, :reference_id


      def benefit_application; end

      def credit_binder_payment; end

      def reverse_binder_payment; end

    end
  end
end