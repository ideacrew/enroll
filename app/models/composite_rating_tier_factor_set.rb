class CompositeRatingTierFactorSet < RatingFactorSet
  validate :only_valid_tier_names

  def self.value_for(carrier_profile_id, year, val)
    record = self.where(carrier_profile_id: carrier_profile_id, active_year: year).first
    record.lookup(val)
  end

  def only_valid_tier_names
    invalid_entries = rating_factor_entries.any? do |rfe|
      !CompositeRatingTier::NAMES.include?(rfe.factor_key)
    end
    if invalid_entries
      errors.add(:rating_factor_entries, "Contain invalid tier names.")
    end
  end
end
