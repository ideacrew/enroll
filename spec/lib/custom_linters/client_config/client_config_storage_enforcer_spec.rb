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

  it "should not show any file differences between committed client and stored client" do
    current_committed_config_ymls.each do |full_filepath|
      filepath_without_root = full_filepath.sub("#{Rails.root}/", '')
      stored_filepath = "#{committed_config_folder}/#{filepath_without_root}"
      result = FileUtils.identical?(full_filepath, stored_filepath)
      raise("#{warning_message}. Unstored changed file is #{full_filepath}") unless result == true
      expect(result).to eq(true)
    end
  end
end