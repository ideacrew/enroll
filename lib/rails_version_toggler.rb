# frozen_string_literal: true

# This class is used for toggling between two rails versions.
# Assumptions:
# The main app directory and components (engines) directories will have .ruby-version and Gemfile/Gemfile.lock files
# with the version to toggles' ruby versions and Gemfiles/Gemfile.lock files named .rails_6_ruby_version and Gemfile_rails_6 and Gemfile.rails_6_lock
class RailsVersionToggler
  attr_accessor :gemfile_and_lock_files, :current_rails_version, :ruby_version_name, :target_rails_version, :target_ruby_version_file_location

  RAIL_VERSIONS = ["5", "6"].freeze

  # TODO: Refactor version switching
  def initialize
    @current_rails_version = Rails.version[0]
    @target_rails_version = RAIL_VERSIONS.detect { |version| current_rails_version != version }
    @target_ruby_version_file_location = "#{Rails.root}/.rails_#{target_rails_version}_ruby_version"
    @ruby_version_name = ".ruby-version"
    @gemfile_and_lock_files = Dir.glob("components/*").map { |component_directory| ["#{Rails.root}/#{component_directory}/#{component_directory}.gemspec", "#{Rails.root}/#{component_directory}/Gemfile.lock"] }
  end

  def toggle
    change_ruby_version
    rename_and_switch_gemfiles
  end

  # TODO: Refactor system executions to a ruby based way of renaming files
  def change_ruby_version
    puts("Renaming current ruby version filename.")
    `cd #{Rails.root} ; mv #{ruby_version_name} ".rails_#{current_rails_version}_ruby_version"`
    puts("Changing target ruby version filename to current ruby version")
    `cd #{Rails.root} ; mv #{target_ruby_version_file_location} #{ruby_version_name}`
  end

  # TODO: Refactor system executions to a ruby based way of renaming files
  def rename_and_switch_gemfiles
    component_gemfiles_and_gemfile_locks.each do |file_info|
      target_directory = file_info.keys[0]
      filenames = file_info.values.flatten
      filenames.each do |filename|
        puts("Renaming #{target_directory} Gemfile.lock and Gemspec files.")
        `mv #{filename} "#{target_directory}/Gemfile.rails_#{current_rails_version}_lock"` if filename.include?("lock")
        `mv "#{target_directory}/Gemfile.rails_#{target_rails_version}_lock" #{filename}` if filename.include?("lock")
        `mv #{filename} "#{target_directory}/Gemfile.rails_#{current_rails_version}"` if filename.exclude?("lock")
        `mv  "#{target_directory}/Gemfile.rails_#{target_rails_version}" #{filename}` if filename.exclude?("lock")
        `mv #{filename} "#{target_directory}/#{target_directory}.gemspec_for_rails_#{current_rails_version}"` if filename.include?("gemspec")
        `mv "#{target_directory}/#{target_directory}.gemspec_for_rails_#{target_rails_version}" #{filename}` if filename.include?("gemspec")
      end
    end
  end

  def component_gemfiles_and_gemfile_locks
    Dir.glob("components/*").map do |component_directory|
      {component_directory => ["#{Rails.root}/#{component_directory}/Gemfile", "#{Rails.root}/#{component_directory}/Gemfile.lock"]}
    end
  end
end
