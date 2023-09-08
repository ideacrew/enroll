# frozen_string_literal: true

# copy of app/helpers/glossary_helper.rb
module GlossaryHelper
  def support_texts(key)
    if l10n("support_texts.#{key}").include? 'application_applicable_year'
      l10n("support_texts.#{key}", application_applicable_year: @application.assistance_year.to_s)
    else
      l10n("support_texts.#{key}")
    end
  end
end
