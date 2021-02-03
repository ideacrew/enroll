# frozen_string_literal: true

# This will check a list of view files for any non ada commplaint html elements
# For Ex: RAILS_ENV=production bundle exec rake view_ada_compliance_linter:lint_git_difference_changed_lines

require "#{Rails.root}/lib/custom_linters/ada_compliance/view_ada_compliance_linter.rb"
require "#{Rails.root}/lib/custom_linters/ada_compliance/view_ada_compliance_linter_helper.rb"
include ViewAdaComplianceLinterHelper

namespace :view_ada_compliance_linter do
  desc("Lints lines from view files changed since mastser for ada compliance")
  task :lint_git_difference_changed_lines do
    puts("No view files too lint.") if branch_changed_filenames_erb.blank?
    return if branch_changed_filenames_erb.blank?
    puts("Linting the following files: #{branch_changed_filenames_erb}") if branch_changed_filenames_erb.present?
    puts("")
    puts("")
    changed_files_with_linting_errors = []
    branch_changed_filenames_erb.each do |filename|
      changed_lines_key_values = {}
      changed_lines_string = changed_lines_from_file_string(filename)
      changed_lines_key_values[filename] = changed_lines_string
      unless erb_files_ada_compliant?(filename)
        changed_files_with_linting_errors << filename
      end
    end
    if changed_files_with_linting_errors.present?
      puts("ADA compliance issues present. Please fix and run again.")
      abort
    else
      puts("ADA Compliance linting complete. No errors present in ERB files.")
    end
  end
end
