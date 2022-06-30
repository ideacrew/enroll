# frozen_string_literal: true

module FinancialAssistance
  module L10nHelper
    def l10n(translation_key, interpolated_keys = {})
      ActionController::Base.helpers.sanitize(t(translation_key, interpolated_keys.merge(default: translation_key.gsub(/\W+/, '').titleize)))
    end

    def l10n_sentence(translation_key, interpolated_keys = {})
      ActionController::Base.helpers.sanitize(t(translation_key, interpolated_keys.merge(default: translation_key)))
    end
  end
end
