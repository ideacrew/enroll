# frozen_string_literal: true

require_relative 'view_translations_linter_helper'

# This wll provide a report showing the status of translations in each individual directory
# To give an idea of what needs to be internationalized
class ViewTranslationsLinterReport
  VIEW_DIRECTORIES = {
    main_app: Dir[Rails.root.join('app/views/**/**/*.html.erb')].uniq,
    benefit_markets: Dir[Rails.root.join('components/benefit_markets/app/views/**/**/*.html.erb')].uniq,
    benefit_sponsors: Dir[Rails.root.join('components/benefit_sponsors/app/views/**/**/*.html.erb')].uniq,
    financial_assistance: Dir[Rails.root.join('components/financial_assistance/app/views/**/**/*.html.erb')].uniq,
    notifier: Dir[Rails.root.join('components/notifier/app/views/**/**/*.html.erb')].uniq,
    sponsored_benefits: Dir[Rails.root.join('components/sponsored_benefits/app/views/**/**/*.html.erb')].uniq,
    transport_gateway: Dir[Rails.root.join('components/transport_gateway/app/views/**/**/*.html.erb')].uniq,
    transport_profiles: Dir[Rails.root.join('components/transport_profiles/app/views/**/**/*.html.erb')].uniq,
    ui_helpers: Dir[Rails.root.join('components/ui_helpers/app/views/**/**/*.html.erb')].uniq
  }.freeze

  def self.run
    VIEW_DIRECTORIES.each do |directory_name, full_view_file_location_filenames|
      self.evaluate_views(directory_name, full_view_file_location_filenames)
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def self.evaluate_views(directory_name, filenames)
    views_missing_translations_both = []
    views_missing_translations_outside_erb = []
    views_missing_translations_inside_erb = []
    views_with_all_translations = []
    filenames.each do |full_file_location|
      if translations_in_erb_tags_present?(full_file_location) && translations_outside_erb_tags_present?(full_file_location)
        views_with_all_translations << full_file_location
      elsif !translations_in_erb_tags_present?(full_file_location) && translations_outside_erb_tags_present?(full_file_location)
        views_missing_translations_inside_erb << full_file_location
      elsif translations_in_erb_tags_present?(full_file_location) && !translations_outside_erb_tags_present?(full_file_location)
        views_missing_translations_outside_erb << full_file_location
      else
        views_missing_translations_both << full_file_location
      end
    end
    if filenames.length == views_with_all_translations.length
      puts("All translations present for #{directory_name}")
    else
      puts("For a total of #{filenames.length} files in the #{directory_name} directory:")
      puts("There are a total of #{views_missing_translations_both.length} views with translations both inside and outside erb missing.")
      puts("There are a total of #{views_missing_translations_outside_erb.length} views with translations outside erb missing.")
      puts("There are a total of #{views_missing_translations_inside_erb.length} views with translations inside erb missing.")
      puts("There are a total of #{views_with_all_translations.length} views with all translations present.")
    end
    puts("")
  end
  # rubocop:enable Metrics/CyclomaticComplexity
end

