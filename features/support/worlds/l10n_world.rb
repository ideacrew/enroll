# frozen_string_literal: true

module L10nWorld
  include HtmlScrubberUtil

  def l10n(translation_key, interpolated_keys={})
    begin
      sanitize_html(I18n.t(translation_key, interpolated_keys.merge(raise: true)))
    rescue I18n::MissingTranslationData
      translation_key.gsub(/\W+/, '').titleize
    end
  end
end

World(L10nWorld)