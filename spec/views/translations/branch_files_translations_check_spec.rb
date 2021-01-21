# frozen_string_literal: true

require 'rails_helper'
require Rails.root.to_s + "/spec/support/erb_translations_linter.rb"

# This will check the git diff for all .html.erb files and match all non HTML/ERB tag substrings
# against all the translations in the database to assure translations are added to the file.

RSpec.describe "Branch Files Translations Spec" do
  # Returns an array of all available translations with special characters removed, downcased
  let(:filename_list) { `git diff --name-only origin/master HEAD | grep .html.erb`.strip.split("\n") }
  # Will read all ERB files and and return an array of all of them as strings
  let(:read_files) { filename_list.map { |view_filename| File.read("#{Rails.root}/#{view_filename}") } }
  # YML file containing whitelisted keys.
  # Note: Do NOT whitelist strings without lead dev approval
  let(:whitelisted_strings_hash) { YAML.load_file(Rails.root.to_s + "/spec/support/fixtures/whitelisted_translation_strings.yml").with_indifferent_access }
  let(:whitelisted_translation_strings_from_erb_tags) do
    all_whitelisted_strings = []
    keys = whitelisted_strings_hash[:whitelisted_translation_strings_from_erb_tags].keys
    keys.each do |key|
      all_whitelisted_strings << whitelisted_strings_hash[:whitelisted_translation_strings_from_erb_tags][key]
    end
    all_whitelisted_strings.flatten
  end
  let(:whitelisted_non_erb_tag_strings) do
    whitelisted_strings_hash[:whitelisted_non_erb_tag_strings][:string_list] + whitelisted_strings_hash[:whitelisted_non_erb_tag_strings][:non_text_method_calls]
  end
  let(:translations_linter) { ErbTranslationsLinter.new(read_files, whitelisted_translation_strings_from_erb_tags, whitelisted_non_erb_tag_strings) }

  it "should not contain any ERB tags containing untranslated strings" do
    expect(translations_linter.all_translations_in_erb_tags?).to eq(true)
  end

  it "should not contain any untranslated substrings outside of HTML tags" do
    expect(translations_linter.all_translations_outside_erb_tags?).to eq(true)
  end
end

