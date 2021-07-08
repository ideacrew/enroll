# frozen_string_literal: true

require 'rails_helper'

# This will enforce preventing additional keys from being added to Settings.yml
# Please use ResourceRegistry.
describe "Client Config Storage Enforcement" do
  let(:current_committed_client) do
    EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.downcase
  end

  let(:committed_config_folder) do
    "#{Rails.root}/config/client_config/#{current_committed_client}"
  end

  let(:current_committed_config_stored_settings_yml_loaded) do
    filepath = "#{committed_config_folder}/config/settings.yml"
    YAML.load_file(filepath).with_indifferent_access
  end

  let(:stored_settings_yml_keys) do
    all_keys = []
    current_committed_config_stored_settings_yml_loaded.each_key do |key|
      all_keys << current_committed_config_stored_settings_yml_loaded[key].keys if current_committed_config_stored_settings_yml_loaded[key].respond_to?(:keys)
    end
    all_keys.flatten
  end

  let(:current_committed_settings_yml_loaded) do
    filepath = "#{Rails.root}/config/settings.yml"
    YAML.load_file(filepath).with_indifferent_access
  end

  let!(:current_committed_settings_yml_loaded_keys) do
    all_keys = []
    current_committed_settings_yml_loaded.each_key do |key|
      all_keys << current_committed_settings_yml_loaded[key].keys if current_committed_settings_yml_loaded[key].respond_to?(:keys)
    end
    all_keys.flatten
  end

  def deprecation_warning(key)
    raise(
      "An additional key, #{key} has been added to Settings.yml. Currently Settings.yml is in the process"\
      " of being deprecated. Please move key to ResourceRegistry."
    )
  end


  it "should not show any additionally added key value pairs" do
    current_committed_settings_yml_loaded_keys.each do |current_settings_yml_key|
      deprecation_warning(current_settings_yml_key) unless stored_settings_yml_keys.include?(current_settings_yml_key)
      expect(stored_settings_yml_keys).to include(current_settings_yml_key)
    end
  end
end
