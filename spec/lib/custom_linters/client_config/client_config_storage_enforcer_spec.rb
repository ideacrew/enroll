# frozen_string_literal: true

require 'rails_helper'

# This will enforce storing changes
describe "Client Config Storage Enforcement" do
  let(:current_committed_client) do
    EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.downcase
  end
  let(:committed_config_folder) do
    "#{Rails.root}/config/client_config/#{current_committed_client}"

  end
  let(:current_committed_config_stored_ymls) do
    Dir.glob("#{committed_config_folder}/system/**/*.yml")
  end
  let(:current_committed_config_ymls) do
    Dir.glob("#{Rails.root}/system/**/*.yml")
  end
  let(:warning_message) do
    "Currently committed configuration does not match stored configuration." \
    " Please run bundle exec rake configuration:store_current_configuration" \
    " to store current configuration"
  end

  let(:non_stored_client_locations) do
    Dir.glob("#{Rails.root}/config/client_config/**").reject { |folder| folder == committed_config_folder }
  end

  let(:non_stored_client_abbreviations) do
    non_stored_client_locations.map { |folder| folder.gsub("#{Rails.root}/config/client_config/", "") }
  end

  let(:non_stored_client_system_folders) do
    non_stored_client_locations.select { |folder| "#{folder}/system" }
  end

  it "should not show any file differences between committed client and stored client" do
    current_committed_config_ymls.each do |full_filepath|
      filepath_without_root = full_filepath.sub("#{Rails.root}/", '')
      stored_filepath = "#{committed_config_folder}/#{filepath_without_root}"
      result = FileUtils.identical?(full_filepath, stored_filepath)
      raise("#{warning_message}. Unstored changed file is #{full_filepath}") unless result == true
      expect(result).to eq(true)
    end
  end

  it "should not show any different keys between current config and OTHER client stored configs" do
    non_stored_client_locations.each do |folder_location|
      missing_keys = []
      client_abbreviation = folder_location.gsub("#{Rails.root}/config/client_config/", "")
      stored_client_registry = ResourceRegistry::Registry.new
      stored_client_registry.configure do |config|
        config.name       = "#{client_abbreviation}_enroll".to_sym
        config.created_at = DateTime.now
        config.load_path  = "#{folder_location}/system"
      end
      EnrollRegistry.each_key do |currently_registered_key|
        missing_keys << currently_registered_key unless stored_client_registry.keys.include?(currently_registered_key)
      end
      error_message = "Stored config for #{client_abbreviation} does not contain the following keys: #{missing_keys}."\
        " Please add these keys to the appropriate stored config file for #{client_abbreviation}."
      raise(error_message) unless missing_keys.blank?
      expect(missing_keys.blank?).to eq(true)
    end
  end
end