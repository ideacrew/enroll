# frozen_string_literal: true
# Run it with this: bundle exec rake app:seed:load_faa_translations

# TODO: refactor this once this is implemented with the other task... for some reason enroll registry wasn't being loaded here
EnrollRegistry = ResourceRegistry::Registry.new

EnrollRegistry.configure do |config|
  config.name       = :enroll
  config.created_at = DateTime.now
  config.load_path = Rails.root.to_s.gsub("/components/benefit_markets/spec/dummy", "") + "/system/config/templates/features"
end
site_key =  EnrollRegistry[:enroll_app].setting(:site_key).item

require 'rake'
require_relative "../../db/seedfiles/translations/en/#{site_key}/financial_assistance"

namespace :seed do
  desc "load translations from faa engine translations file"
  task :load_faa_translations => :environment do
    # TODO: Load from file
    # en =  YAML::load(File.read(File.open("db/seedfiles/translations/en/faa_translations.rb",'r')))
    puts "Loading en FAA translation...."

    ::FINANCIAL_ASSISTANCE_TRANSLATIONS.each_key do |key|
      value = ::FINANCIAL_ASSISTANCE_TRANSLATIONS[key]
      Translation.where(key: key).first_or_create.update_attributes!(value: "\"#{value}\"")
    end
    puts "Loaded #{Translation.all.count} translations."
  end
end
