module BenefitSponsors
  module L10nHelper
    include HtmlScrubberUtil

    def l10n(translation_key, interpolated_keys={})
      santize_html(t(translation_key, interpolated_keys.merge(default: translation_key.gsub(/\W+/, '').titleize)))
    end
  end
end
