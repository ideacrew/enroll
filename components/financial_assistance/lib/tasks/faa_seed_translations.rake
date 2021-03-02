# frozen_string_literal: true
# Run it with this: bundle exec rake app:seed:load_faa_translations

require 'rake'
require_relative '../../db/seedfiles/translations/en/faa_translations'

namespace :seed do
  desc "load translations from faa engine translations file"
  task :load_faa_translations => :environment do
    # TODO: Load from file
    # en =  YAML::load(File.read(File.open("db/seedfiles/translations/en/faa_translations.rb",'r')))
    puts "Loading en FAA translation...."

    ::FaaTranslations::ASSISTANCE_TRANSLATIONS.each_key do |key|
      value = ::FaaTranslations::ASSISTANCE_TRANSLATIONS[key]
      Translation.where(key: key).first_or_create.update_attributes!(value: "\"#{value}\"")
    end
    puts "Loaded #{Translation.all.count} translations."
  end
end
