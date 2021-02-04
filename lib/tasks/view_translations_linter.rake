# frozen_string_literal: true

# This will check a list of view files for any untranslated strings
# For Ex: RAILS_ENV=production bundle exec rake view_translations_linter:lint_git_difference_changed_lines

require "#{Rails.root}/spec/support/view_translations_linter.rb"

namespace :view_translations_linter do
  desc("Lints lines from view files changed since master")
  task :lint_git_difference_changed_lines do
    # Approved list data
    approved_translations_hash = YAML.load_file("#{Rails.root}/spec/support/fixtures/approved_translation_strings.yml").with_indifferent_access

    approved_translation_strings_in_erb_tags = []
    keys = approved_translations_hash[:approved_translation_strings_in_erb_tags].keys
    keys.each do |key|
      approved_translation_strings_in_erb_tags << approved_translations_hash[:approved_translation_strings_in_erb_tags][key]
    end
    approved_translation_strings_in_erb_tags = approved_translation_strings_in_erb_tags.flatten

    approved_translation_strings_outside_erb_tags = []
    keys = approved_translations_hash[:approved_translation_strings_outside_erb_tags].keys
    keys.each do |key|
      approved_translation_strings_outside_erb_tags << approved_translations_hash[:approved_translation_strings_outside_erb_tags][key]
    end

    approved_translation_strings_outside_erb_tags = approved_translation_strings_outside_erb_tags.flatten
    # Returns array of changed files ending in .html.erb and not .html.erb specss
    # TOOD: Returns nil for some reason when this is added grep -v 'spec/'  needs to be included
    changed_filenames_erb = `git diff --name-only origin/master HEAD | grep .html.erb`.strip.split("\n").reject { |filename| filename.match('_spec.rb').present? }
    puts("Linting the following ERB files: #{changed_filenames_erb}") if changed_filenames_erb.present?
    puts("")
    puts("")
    changed_erb_files_with_linting_errors = []
    changed_filenames_erb.each do |filename|
      changed_lines_key_values = {}
      changed_lines_string = `git diff HEAD^ HEAD  --unified=0 #{filename} | tail +6 | sed -e 's/^\+//'`
      changed_lines_key_values[filename] = changed_lines_string
      translations_linter_in_erb = ViewTranslationsLinter.new(changed_lines_key_values, approved_translation_strings_in_erb_tags, 'in_erb')
      translations_linter_outside_erb = ViewTranslationsLinter.new(changed_lines_key_values, approved_translation_strings_outside_erb_tags, 'outside_erb')
      unless translations_linter_in_erb.all_translations_present?
        changed_erb_files_with_linting_errors << filename
      end
      unless translations_linter_outside_erb.all_translations_present?
        changed_erb_files_with_linting_errors << filename
      end
    end
    if changed_erb_files_with_linting_errors.present?
      puts("Please modify your ERB and place them in translation helper tags with a coorelating translation or add them to the approved string list.")
      abort
    else
      puts("Translations linting complete. No errors present.")
    end
    # Haml
    changed_filenames_haml = `git diff --name-only origin/master HEAD | grep .html.haml`.strip.split("\n").reject { |filename| filename.match('_spec.rb').present? }
    puts("Linting the following haml files: #{changed_filenames_haml}") if changed_filenames_haml.present?
    puts("")
    puts("")
    changed_haml_files_with_linting_errors = []
    changed_filenames_haml.each do |filename|
      changed_lines_key_values = {}
      changed_lines_string = `git diff HEAD^ HEAD  --unified=0 #{filename} | tail +6 | sed -e 's/^\+//'`
      changed_lines_key_values[filename] = changed_lines_string
      translations_linter_haml= ViewTranslationsLinter.new(changed_lines_key_values, approved_translation_strings_in_erb_tags, 'in_haml_ruby_tags')
      unless translations_linter_haml.all_translations_present?
        changed_haml_files_with_linting_errors << filename
      end
    end
    if translations_linter_haml.present?
      puts("Please modify your HAML and place them in translation helper tags with a coorelating translation or add them to the approved string list.")
      abort
    else
      puts("Translations linting complete. No errors present.")
    end
  end
end
