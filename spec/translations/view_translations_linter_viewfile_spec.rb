require 'rails_helper'

RSpec.describe "View File Translations Linting" do
  context "app/views/" do
    let(:filenames) { Dir[Rails.root.join('app/views/**/**/*.html.erb')].uniq }
    it "should have all translations" do
      views_missing_translations = []
      views_with_all_translations = []
      filenames.each do |full_file_location|
        if translations_in_erb_tags_present?(full_file_location) || translations_outside_erb_tags_present?(full_file_location)
          views_missing_translations << full_file_location
        else
          views_with_all_translations << full_file_location
        end
      end
      puts("For a total of #{filenames.length} files in the main app directory:")
      puts("There are a total of #{views_missing_translations.length} views with translations missing.")
      puts("There are a total of #{views_with_all_translations.length} views with all translations present.")
    end
  end
end