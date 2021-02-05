require 'rails_helper'

RSpec.describe "View File Translations Linting" do
  context "main app/views/" do
    let(:filenames) { Dir[Rails.root.join('app/views/**/**/*.html.erb')].uniq }
    it "should have all translations" do
      evaluation_results(filenames)
    end
  end

  context "components" do
    context "benefit markets" do
      let(:filenames) { Dir[Rails.root.join('components/benefit_markets/app/views/**/**/*.html.erb')].uniq }
      it "should have all translations" do
        evaluation_results(filenames)
      end
    end

    context "benefit sponsors" do
      let(:filenames) { Dir[Rails.root.join('components/benefit_sponsors/app/views/**/**/*.html.erb')].uniq }
      it "should have all translations" do
        evaluation_results(filenames)
      end
    end

    context "financial assistance" do
      let(:filenames) { Dir[Rails.root.join('components/financial_assistance/app/views/**/**/*.html.erb')].uniq }
      it "should have all translations" do
        evaluation_results(filenames)
      end
    end

    context "notifier" do
      let(:filenames) { Dir[Rails.root.join('components/notifier/app/views/**/**/*.html.erb')].uniq }
      it "should have all translations" do
        evaluation_results(filenames)
      end
    end

    context "sponsored benefits" do
      let(:filenames) { Dir[Rails.root.join('components/sponsored_benefits/app/views/**/**/*.html.erb')].uniq }
      it "should have all translations" do
        evaluation_results(filenames)
      end
    end

    context "transport gateway" do
      let(:filenames) { Dir[Rails.root.join('components/transport_gateway/app/views/**/**/*.html.erb')].uniq }
      it "should have all translations" do
        evaluation_results(filenames)
      end
    end

    context "transport profiles" do
      let(:filenames) { Dir[Rails.root.join('components/transport_profiles/app/views/**/**/*.html.erb')].uniq }
      it "should have all translations" do
        evaluation_results(filenames)
      end
    end

    context "ui helpers" do
      let(:filenames) { Dir[Rails.root.join('components/ui_helpers/app/views/**/**/*.html.erb')].uniq }
      it "should have all translations" do
        evaluation_results(filenames)
      end
    end
  end

  def evaluation_results(filenames)
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
    unless filenames.length == views_with_all_translations.length
      puts("For a total of #{filenames.length} files in the directory:")
      puts("There are a total of #{views_missing_translations_both.length} views with translations both inside and outside erb missing.")
      puts("There are a total of #{views_missing_translations_outside_erb.length} views with translations outside erb missing.")
      puts("There are a total of #{views_missing_translations_inside_erb.length} views with translations inside erb missing.")
      puts("There are a total of #{views_with_all_translations.length} views with all translations present.")
    end
    expect(filenames.length == views_with_all_translations.length).to eq(true)
  end
end