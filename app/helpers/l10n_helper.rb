# frozen_string_literal: true

module L10nHelper
  def l10n(translation_key, interpolated_keys = {})
    Rails.logger.error {"#L10nHelper passed non string key: #{translation_key.inspect}"} unless translation_key.is_a?(String)
    return "Translation Missing" unless translation_key.is_a?(String)
    # https://www.rubydoc.info/github/svenfuchs/i18n/master/I18n%2FBase:translate
    if interpolated_keys.present?
      t(translation_key, **interpolated_keys.merge(default: translation_key.gsub(/\W+/, '').titleize), default: "Translation Missing for #{translation_key}").html_safe
    else
      t(translation_key, default: "Translation Missing for #{translation_key}")
    end
  end
end
