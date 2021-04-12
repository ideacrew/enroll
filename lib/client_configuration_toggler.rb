# frozen_string_literal: true

# This class is used to swap the applicaiton wide configuration between different clients (I.E. DC to Maine)
# "#{Rails.root}/config/client_configuration/#{ENV['state_abbreviation']/templates/**.yml"
# with the version to toggles' ruby versions and Gemfiles/Gemfile.lock files named .rails_6_ruby_version and Gemfile_rails_6 and Gemfile.rails_6_lock
class ClientConfigurationToggler < MongoidMigrationTask
  def system_config_target_folder
    "#{Rails.root}/system/"
  end

  def target_config_folder
    "#{Rails.root}/config/client_configuration/#{@target_client_state_abbreviation}"
  end

  def old_config_folder
    "#{Rails.root}/config/client_configuration/#{@old_configured_state_abbreviation}"
  end

  def old_configured_state_abbreviation
    EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.downcase
  end

  def target_client_state_abbreviation
    missing_state_abbreviation_message = "Please set your target client as an arguement. " \
    "The rake command should look like:" \
    " RAILS_ENV=production bundle exec rake client_configuration_toggler:migrate state_abbreviation='me'"
    raise(missing_state_abbreviation_message) if ENV['state_abbreviation'].blank?
    incorrect_state_abbreviation_format_message = "Incorrect state abbreviation length. Set abbreviation to two letters like 'MA' or 'DC'"
    raise(incorrect_state_abbreviation_format_message) if ENV['state_abbreviation'].length > 2
    ENV['state_abbreviation'].downcase
  end

  def move_target_configuration_to_system_folder
    target_configuration_files = Dir.glob("#{target_config_folder}/system/**/*.yml")
    raise("No configuration files present in target directory.") if target_configuration_files.blank?
    FileUtils.move("#{target_config_folder}/system", system_config_target_folder)
  end

  def store_old_configuration
    FileUtils.move(system_config_target_folder, "#{@old_config_folder}/system")
  end

  def copy_current_configuration_to_engines
    Dir.glob("components/*").each do |engine_folder_name|
      FileUtils.cp("#{target_config_folder}/system", "#{Rails.root}/#{engine_folder_name}/system")
      FileUtils.cp("#{target_config_folder}/system", "#{Rails.root}/#{engine_folder_name}/spec/dummy/system")
    end
  end

  # TODO: Ideally, this method will be deprecated eventually.
  # There are some certain files in app/assets and possibly other files which will be
  # referenced directly in the config/client_configuration/#{target_client_state_abbreviation} folder
  # to be swapped out quickly
  def swap_app_assets_and_straggler_files
    Dir.glob(target_config_folder).reject { |file| file.include?('system') }.each do |filename_in_config_directory|
      # Cut off the filename parts with config namespace
      actual_filename_in_enroll = filename_in_config_directory.sub(old_config_folder, '')
      # First move the old one to storage
      # Now will be, "config/client_configuration"
      FileUtils.move(actual_filename_in_enroll, "#{store_old_configuration}/#{actual_filename_in_enroll}")
      # Move the new one to the live app
      FileUtils.move(filename_in_config_directory, actual_filename_in_enroll)
    end
  end

  def migrate
    puts("Initializing client configuration toggle. System configuration will be moved from #{old_configured_state_abbreviation} to #{target_client_state_abbreviation}")
    @old_configured_state_abbreviation = old_configured_state_abbreviation
    @target_client_state_abbreviation = target_client_state_abbreviation
    store_old_configuration
    move_target_configuration_to_system_folder
    copy_current_configuration_to_engines
    swap_app_assets_and_straggler_files
    puts("Client configuration toggle complete system is now set to #{current_configured_client_state_abbreviation}")
  end
end
