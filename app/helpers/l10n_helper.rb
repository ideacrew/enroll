module L10nHelper
  def l10n(translation_key, interpolated_keys = {})
    I18n.t(translation_key, interpolated_keys).html_safe
  rescue I18n::MissingTranslationData
    translation_key.gsub(/\W+/, '').titleize
  end
end
