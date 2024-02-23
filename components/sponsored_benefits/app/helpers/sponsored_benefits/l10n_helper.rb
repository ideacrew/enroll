# frozen_string_literal: true

module SponsoredBenefits
  # Translation helper for sponsored benefits component
  module L10nHelper
    def l10n(translation_key, interpolated_keys = {})
      t(translation_key, interpolated_keys.merge(default: translation_key.gsub(/\W+/, '').titleize))
    end
  end
end
