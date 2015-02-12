class Enrollee
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :policy

  field :person_id, type: BSON::ObjectId
  field :carrier_member_id, type: String
  field :carrier_policy_id, type: String

  field :premium_amount_in_cents, type: Integer

  field :coverage_start_on, type: Date
  field :coverage_end_on, type: Date

  validates_presence_of :person_id, :relationship_kind

  def person=(new_person)
  end

  def person
  end

  def premium_amount_in_dollars=(new_premium)
    premium_amount_in_cents = dollars_to_cents(new_premium)
  end

  def premium_amount_in_dollars
    cents_to_dollars(premium_amount_in_cents)
  end

  def calculate_premium_using(plan, rate_start_date)
    self.pre_amt = sprintf("%.2f", plan.rate(rate_start_date, self.coverage_start_on, self.member.dob).amount)
  end

  def reference_premium_for(plan, rate_date)
    plan.rate(rate_date, coverage_start_on, member.dob).amount
  end

  def coverage_end?
    coverage_end_on.present?
  end

private

  def dollars_to_cents(amount_in_dollars)
    Rational(amount_in_dollars) * Rational(100) if amount_in_dollars
  end

  def cents_to_dollars(amount_in_cents)
    (Rational(amount_in_cents) / Rational(100)).to_f if amount_in_cents
  end



end
