module L10nHelper
  def l10n(translation_key, interpolated_keys={})
    t(translation_key, interpolated_keys)
  end
end
