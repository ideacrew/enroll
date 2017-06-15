class EmployerGroupSizeRatingFactorSet < RatingFactorSet
  validates_numericality_of :max_integer_factor_key, :allow_blank => false

  def self.value_for(carrier_profile_id, year, val)
    record = self.where(carrier_profile_id: carrier_profile_id, active_year: year).first
    record.lookup(val)
  end

  def lookup(val)
    lookup_key = (val > max_integer_factor_key) ? max_integer_factor_key : val
    super(lookup_key.to_s)
  end
end
