class EmployerParticipationRateRatingFactorSet < RatingFactorSet
  def lookup(val)
    transformed_value = val.respond_to?(:round) ? val.round.to_s : val
    super(transformed_value)
  end
end
