class PaymentTransaction
  include Mongoid::Document

  field :transaction_id, type: String
  field :submitted_at, type: DateTime
  before_create :set_submitted_at, :set_transaction_id

  index({transaction_id:  1}, {unique: true})
  index({submitted_at: 1})

  private

  def set_submitted_at
    self.submitted_at = TimeKeeper.date_of_record
  end

  def generate_transaction_id
    @transaction_id ||= begin
      ran = Random.new
      current_time = Time.now.utc
      reference_number_base = current_time.strftime("%Y%m%d%H%M%S") + current_time.usec.to_s[0..2]
      reference_number_base + sprintf("%05i",ran.rand(65535))
    end
  end

  def set_transaction_id
    self.transaction_id = generate_transaction_id
  end

end