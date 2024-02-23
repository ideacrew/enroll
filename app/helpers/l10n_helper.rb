# frozen_string_literal: true

module L10nHelper
  include ActionView::Helpers::TranslationHelper
  include HtmlScrubberUtil
  def l10n(translation_key, interpolated_keys = {})
    Rails.logger.error {"#L10nHelper passed non string key: #{translation_key.inspect}"} unless translation_key.is_a?(String)
    # https://www.rubydoc.info/github/svenfuchs/i18n/master/I18n%2FBase:translate
    result = if translation_key.is_a?(String) && interpolated_keys.present?
               t(
                 translation_key,
                 **interpolated_keys.merge(default: translation_key.gsub(/\W+/, '').titleize),
                 default: translation_key.to_s&.gsub(/\W+/, '')&.titleize
               )
             else
               t(translation_key, default: translation_key.to_s&.gsub(/\W+/, '')&.titleize)
             end
    result.respond_to?(:html_safe) ? sanitize_html(result) : translation_key.to_s
  end
end
