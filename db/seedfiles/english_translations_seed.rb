Dir.glob('db/seedfiles/translations/*').each do |file|
  require_relative 'translations/' + File.basename(file,File.extname(file))
end

puts "*"*80
puts "::: Generating English Translations :::"

MAIN_TRANSLATIONS = {
  "en.shared.my_portal_links.my_insured_portal" => "My Insured Portal"
}
translations = [
  BOOTSTRAP_EXAMPLE_TRANSLATIONS,
  BUTTON_PANEL_EXAMPLE_TRANSLATIONS,
  LAYOUT_TRANSLATIONS,
  MAIN_TRANSLATIONS,
  USERS_ORPHANS_TRANSLATIONS,
  WELCOME_INDEX_TRANSLATIONS,
  BUTTON_PANEL_EXAMPLE_TRANSLATIONS
  WELCOME_INDEX_TRANSLATIONS
].reduce({}, :merge)

translations.keys.each do |k|
  Translation.where(key: k).first_or_create.update_attributes!(value: "\"#{translations[k]}\"")
end

puts "::: English Translations Complete :::"
puts "*"*80
