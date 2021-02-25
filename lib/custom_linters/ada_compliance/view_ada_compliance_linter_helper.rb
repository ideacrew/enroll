# frozen_string_literal: true

require_relative 'view_ada_compliance_linter'

# This module defines methods related to ViewAdaComplianceLinter to be reused in
# Rake files, specs, etc.
module ViewAdaComplianceLinterHelper
  # Approved list data
  # TODO: Find out how alloow list should be handled

  def erb_files_ada_compliant?(file_location)
    stringified_view = File.read(file_location.to_s)
    ViewAdaComplianceLinter.new({file_location.to_s => stringified_view}, compliance_rules_hash).views_ada_compliant?
  end

  def compliance_rules_hash
    YAML.load_file("#{Rails.root}/config/translations_linter/approved_translation_strings.yml").with_indifferent_access
  end

  def branch_changed_filenames_erb
    # Returns array of changed files ending in .html.erb and not .html.erb specs
    # TOOD: Returns nil for some reason when this is added grep -v 'spec/'  needs to be included
    `git diff --name-only origin/trunk HEAD | grep .html.erb`.strip.split("\n").reject { |filename| filename.match('_spec.rb').present? }
  end

  def changed_lines_from_file_string(filename)
    `git diff HEAD^ HEAD  --unified=0 #{filename} | tail +6 | sed -e 's/^\+//'`
  end
end