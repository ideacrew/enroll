###

### Notes on Usage

## https://github.com/rails/rails/issues/16499
## http://api.rubyonrails.org/v5.1/classes/ActionView/Helpers/TranslationHelper.html#method-i-translate

## Keys in load files are prefixed with the relevant language shortstring (e.g 'en')
## Keys can be based on view path if using 'dot' notation.
##    A localization used in app/views/posts/new.html.erb
##    can be referenced by l10n('.hello') which would refer to a translation
##    created in the load file like "en.posts.new.hello"

##    Sometimes this does not work as expected inside partials,
##    or you need to use the same string in several views. In this case you can use
##    direct strings to reference the translation.
##    "en.posts.new.hello" => l10n("posts.new.hello")

module L10nHelper
  def l10n(translation_key, interpolated_keys={})
    caller_view = caller[0]
    begin
      t(translation_key, interpolated_keys.merge(raise: true))
    rescue I18n::MissingTranslationData
      puts "****"
      puts "Key #{translation_key} requested but not found"
      puts "#{caller_view}"
      puts "****"
      translation_key.gsub(/\W+/, '').titleize
    end
  end
end
