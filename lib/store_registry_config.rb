# frozen_string_literal: true

# Stores the current client configuration in config/client_config/#{state_abbreviation}/system
# If there is a current client configuration there, it will store that configuration first in
# config/client_config/#{state_abbreviation}/todays_date_config
class StoreRegistryConfig < MongoidMigrationTask
  def current_config_folder
    "#{Rails.root}/system"
  end

  def target_config_folder
    "#{Rails.root}/config/client_config/#{@current_configured_state_abbreviation}"
  end

  def files_present_in_target_storage?
    Dir.glob("#{@target_config_folder}/system/**/*").present?
  end

  def copy_last_set_of_config_files
    return unless files_present_in_target_storage?
    old_config_storage_folder = "#{TimeKeeper.date_of_record.to_s.gsub('/', '_')}_#{@current_configured_state_abbreviation}_config"
    puts("Set of config files for #{@current_configured_state_abbreviation} present. Making copy of those in #{@target_config_folder}/#{old_config_storage_folder}")
    `cd #{target_config_folder}; mkdir #{old_config_storage_folder}; cd; cp -r #{@target_config_folder}/system #{@target_config_folder}/#{old_config_storage_folder}`
  end

  def current_configured_state_abbreviation
    EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.downcase
  end

  def copy_current_system_configuration_to_storage
    `cp -r #{Rails.root}/system #{@target_config_folder}`
  end

  def migrate
    @current_config_folder = current_config_folder
    @current_configured_state_abbreviation = current_configured_state_abbreviation
    @target_config_folder = target_config_folder
    puts("Initializing current configuration store. Current storage in #{@current_config_folder} will be stored in  #{@target_config_folder}.")
    copy_last_set_of_config_files
    copy_current_system_configuration_to_storage
    puts("Storing current client configuration complete.")
  end
end
