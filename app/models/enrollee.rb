class Enrollee
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :policy

  field :person_id, type: BSON::ObjectId
  field :carrier_member_id, type: String
  field :carrier_policy_id, type: String

  field :premium_in_cents, type: Integer

  field :coverage_start_on, type: Date
  field :coverage_end_on, type: Date

  validates_presence_of :person_id, :coverage_start_on

  before_save :set_premium

  def person=(new_person)
    raise ArgumentError.new("expected Person class") unless new_person.is_a? Person
    self.person_id = new_person._id
  end

  def person
    Person.find(self.person_id) unless person_id.nil?
  end

  def set_premium
    return if policy.plan.blank? || coverage_start_age.blank?

    premium = Display::Premium.lookup(person.gender, coverage_start_age)
    premium_in_cents = premium.amount_in_cents
  end

  def coverage_start_age
    return if person.blank? || parent.coverage_start_on.blank?
    age = coverage_start_on.year - person.dob.year

    # Shave off one year if coverage starts before birthday
    if coverage_start_on.month == person.dob.month
      age -= 1 if coverage_start_on.day < person.dob.day
    else
      age -= 1 if coverage_start_on.month < person.dob.month
    end

    age
  end

  def premium_in_dollars=(new_premium)
    premium_in_cents = dollars_to_cents(new_premium)
  end

  def premium_in_dollars
    cents_to_dollars(premium_in_cents)
  end

private
  def dollars_to_cents(amount_in_dollars)
    Rational(amount_in_dollars) * Rational(100) if amount_in_dollars
  end

  def cents_to_dollars(amount_in_cents)
    (Rational(amount_in_cents) / Rational(100)).to_f if amount_in_cents
  end



end
