# frozen_string_literal: true

module L10nHelper
  include ActionView::Helpers::TranslationHelper
  include HtmlScrubberUtil

  # @note Due to a caching issue in Rails 6.1, the `MISSING_TRANSLATION` object from
  #   `ActionView::Helpers::TranslationHelper` is cached in the I18n cache and read back as a
  #   different object. This issue occurs when calling `t(translation_key, default: translation_key.to_s&.gsub(/\W+/, '')&.titleize)`
  #   twice, where the value is returned back as a different object the second time. This issue might be fixed in Rails 7.0.4.
  #   To avoid this issue, we are using `I18n.t` instead of `t`.
  def l10n(translation_key, interpolated_keys = {})
    Rails.logger.error {"#L10nHelper passed non string key: #{translation_key.inspect}"} unless translation_key.is_a?(String)
    # https://www.rubydoc.info/github/svenfuchs/i18n/master/I18n%2FBase:translate

    result = if translation_key.is_a?(String) && interpolated_keys.present?
               I18n.t(
                 translation_key,
                 **interpolated_keys.merge(default: translation_key.gsub(/\W+/, '').titleize),
                 default: translation_key.to_s&.gsub(/\W+/, '')&.titleize
               )
             else
               I18n.t(translation_key, default: translation_key.to_s&.gsub(/\W+/, '')&.titleize)
             end
    result.respond_to?(:html_safe) ? sanitize_html(result) : translation_key.to_s
  end
end
