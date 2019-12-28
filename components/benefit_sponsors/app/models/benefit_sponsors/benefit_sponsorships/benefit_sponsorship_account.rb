module BenefitSponsors
  class BenefitSponsorships::BenefitSponsorshipAccount
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :benefit_sponsorship, class_name: "::BenefitSponsors::BenefitSponsorships::BenefitSponsorship"

    embeds_many :financial_transactions,
                class_name: "::BenefitSponsors::BenefitSponsorships::FinancialTransaction",
                inverse_of: :benefit_sponsorship_account

    embeds_many :current_statement_activities,
                class_name: "::BenefitSponsors::BenefitSponsorships::CurrentStatementActivity",
                inverse_of: :benefit_sponsorship_account

    field :next_premium_due_on, type: Date
    field :next_premium_amount, type: Money

    field :message, type: String
    field :past_due, type: Money
    field :previous_balance, type: Money
    field :new_charges, type: Money
    field :adjustments, type: Money
    field :payments, type: Money
    field :total_due, type: Money
    field :current_statement_date, type: Date

    field :aasm_state, type: String, default: "binder_pending"

    accepts_nested_attributes_for :financial_transactions

    def payments_since_last_invoice
      current_statement_date.present? ? current_statement_activities.where(:posting_date.gt => current_statement_date, :type => "Payments").to_a : []
    end

    def adjustments_since_last_invoice
      current_statement_date.present? ? current_statement_activities.where(:posting_date.gt => current_statement_date, :type => "Adjustments").to_a : []
    end

    def last_premium_payment
      return premium_payments.first if premium_payments.size == 1

      premium_payments.order_by(:paid_on.desc).limit(1).first
    end

    def self.find(id)
      org = BenefitSponsorships::Organizations::Organization.where(:"benefit_sponsorship.benefit_sponsorship_account._id" => id)
      org.benefit_sponsorships.first.benefit_sponsorship_account
    end

  end
end