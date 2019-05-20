# frozen_string_literal: true

module BenefitSponsors
  module BenefitSponsorships
    class FinancialTransaction
      include Mongoid::Document
      include Mongoid::Timestamps

      field :payment_type,                     type: String
      # field :amount,                         type: Money
      # field :transaction_date,               type: Date
      # field :payment_date,                   type: Date
      # field :submitted_at,                   type: DateTime
      field :benefit_application_id,           type: BSON::ObjectId
      field :kind,                             type: String

      index({ benefit_application_id:  1 })

      def benefit_application; end

      def credit_binder_payment; end

      def reverse_binder_payment; end

    end
  end
end