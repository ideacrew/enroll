# frozen_string_literal: true

module FinancialAssistance
  module L10nHelper
    def l10n(translation_key, interpolated_keys = {})
      I18n.t(translation_key, interpolated_keys.merge(default: translation_key.gsub(/\W+/, ''))).html_safe
    end
  end
end
