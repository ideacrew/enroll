# frozen_string_literal: true

# Stores the current client configuration in config/client_config/#{state_abbreviation}/system
class StoreRegistryConfig < MongoidMigrationTask
  def current_config_folder
    "#{Rails.root}/system"
  end

  def target_config_folder
    "#{Rails.root}/config/client_config/#{@current_configured_state_abbreviation}"
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
    copy_current_system_configuration_to_storage
    puts("Storing current client configuration complete.")
  end
end
