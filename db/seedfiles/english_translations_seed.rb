Dir.glob('db/seedfiles/translations/en/*').each do |file|
  puts file unless Rails.env.test?
  require_relative 'translations/en/' + File.basename(file,File.extname(file))
end

puts "*"*80 unless Rails.env.test?
puts "::: Generating English Translations :::" unless Rails.env.test?

MAIN_TRANSLATIONS = {
  "en.shared.my_portal_links.my_insured_portal" => "My Insured Portal",
  "en.shared.my_portal_links.my_broker_agency_portal" => "My Broker Agency Portal",
  "en.shared.my_portal_links.my_general_agency_portal" => "My General Agency Portal",
  "en.shared.my_portal_links.my_employer_portal" => "My Employer Portal",
  "en.shared.my_portal_links.did_you_know" => "Did You Know?",
  "en.shared.my_portal_links.portals_helpers_message" => "You can move between your insured, employer, broker accounts using this My Portals link.",
  "en.shared.my_portal_links.add_employee_role" => "Add Employee Role",
  "en.shared.my_portal_links.add_consumer_role" => "Add Consumer Role"
}
translations = [
  BOOTSTRAP_EXAMPLE_TRANSLATIONS,
  BUTTON_PANEL_EXAMPLE_TRANSLATIONS,
  LAYOUT_TRANSLATIONS,
  MAIN_TRANSLATIONS,
  USERS_ORPHANS_TRANSLATIONS,
  WELCOME_INDEX_TRANSLATIONS,
  BUTTON_PANEL_EXAMPLE_TRANSLATIONS,
  INSURED_TRANSLATIONS,
  BROKER_AGENCIES_TRANSLATIONS,
  HBX_PROFILES_TRANSLATIONS,
  DEVISE_TRANSLATIONS
].reduce({}, :merge)

puts "TRANSLATIONS" unless Rails.env.test?
p translations unless Rails.env.test?

translations.keys.each do |k|
  Translation.where(key: k).first_or_create.update_attributes!(value: "\"#{translations[k]}\"")
end

puts "::: English Translations Complete :::" unless Rails.env.test?
puts "*"*80 unless Rails.env.test?
