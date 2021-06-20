# frozen_string_literal: true

site_key = EnrollRegistry[:enroll_app].settings(:site_key).item

translations_to_seed = []
# All filenames should be in a pattern such as
# broker_agencies.rb
# with a constant like
# BROKER_AGENCIES_TRANSLATIONS
seedfile_locations = ["db/seedfiles/translations/en/#{site_key}/"]
seedfile_locations += ["components/financial_assistance/db/seedfiles/translations/en/#{site_key}/"] if EnrollRegistry.feature_enabled?(:financial_assistance)

seedfile_locations.each do |seedfile_location|
  Dir.glob("#{seedfile_location}*").each do |filename|
    puts("Requiring #{filename}")
    require Rails.root.to_s + "/" + filename
    # Save the constant from the file
    str2_markerstring = ".rb"
    translations_to_seed << "#{filename[/#{seedfile_location}(.*?)#{str2_markerstring}/m, 1]}_translations".upcase.constantize
  end
end

MAIN_TRANSLATIONS = {
  :'en.shared.my_portal_links.my_insured_portal' => 'My Insured Portal',
  :'en.shared.my_portal_links.my_broker_agency_portal' => 'My Broker Agency Portal',
  :'en.shared.my_portal_links.my_general_agency_portal' => 'My General Agency Portal',
  :'en.shared.my_portal_links.my_employer_portal' => 'My Employer Portal'
}.freeze
translations_to_seed << MAIN_TRANSLATIONS

puts '*' * 80 unless Rails.env.test?
puts "::: Generating English Translations for Site Key #{site_key} :::"


translations_to_seed.each do |translations_hash|
  translations_hash.keys.each do |key|
    Translation.where(key: key).first_or_create.update_attributes!(value: "\"#{translations_hash[key]}\"")
  end
end

puts "::: English Translations for #{site_key} complete. There are a total of #{Translation.all.count} translations present. :::"
puts '*' * 80 unless Rails.env.test?
