module ViewTranslationsLinterHelper
  # Approved list data
  def approved_translations_hash
    YAML.load_file("#{Rails.root}/config/translations_linter/approved_translation_strings.yml").with_indifferent_access
  end

  def branch_changed_filenames
    # Returns array of changed files ending in .html.erb and not .html.erb specs
    # TOOD: Returns nil for some reason when this is added grep -v 'spec/'  needs to be included
    changed_filenames = `git diff --name-only origin/master HEAD | grep .html.erb`.strip.split("\n").reject { |filename| filename.match('_spec.rb').present? }
  end
  
  def changed_lines_from_file_string(filename)
    `git diff HEAD^ HEAD  --unified=0 #{filename} | tail +6 | sed -e 's/^\+//'`
  end

  def approved_translation_strings_in_erb_tags 
    translsations = []
    keys = approved_translations_hash[:approved_translation_strings_in_erb_tags].keys
    keys.each do |key|
      translations << approved_translations_hash[:approved_translation_strings_in_erb_tags][key]
    end
    translations.flatten
  end

  def approved_translation_strings_outside_erb_tags 
    translations = []
    keys = approved_translations_hash[:approved_translation_strings_outside_erb_tags].keys
    keys.each do |key|
      translations << approved_translations_hash[:approved_translation_strings_outside_erb_tags][key]
    end
    translations.flatten
  end
end