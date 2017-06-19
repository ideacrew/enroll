class EmployerParticipationRateRatingFactorSet < RatingFactorSet
  def self.value_for(carrier_profile_id, year, val)
    record = self.where(carrier_profile_id: carrier_profile_id, active_year: year).first
    record.lookup(val)
  end

  def lookup(val)
    transformed_value = val.respond_to?(:round) ? val.round.to_s : val
    super(transformed_value)
  end
end
