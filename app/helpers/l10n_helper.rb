# frozen_string_literal: true

module L10nHelper
  def l10n(translation_key, interpolated_keys = {})
    Rails.logger.error {"#L10nHelper passed non string key: #{translation_key.inspect}"} unless translation_key.is_a?(String)
    return "Translation Missing" unless translation_key.is_a?(String)
    # https://www.rubydoc.info/github/svenfuchs/i18n/master/I18n%2FBase:translate
    titleized_key = translation_key.to_s&.gsub(/\W+/, '')&.titleize
    if interpolated_keys.present?
      t(
        translation_key,
        **interpolated_keys.merge(default: translation_key.gsub(/\W+/, '').titleize),
        default: titleized_key
      ).html_safe
    else
      t(translation_key, default: titleized_key).html_safe
    end
  end
end
