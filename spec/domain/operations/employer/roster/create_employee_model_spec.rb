# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Employer::Roster::CreateEmployeeModel, dbclean: :after_each do
  subject { described_class.new.call(input_params) }

  describe '#call' do
    # let(:employer_profile) { FactoryBot.create(:employer_profile) }
    let(:file) { double }
    let(:temp_file) { double }
    let(:bucket_name) { 'employer_roster_upload' }
    let(:uri) { "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}{#sample-key}" }
    let(:file_path) { File.dirname(__FILE__) }
    let!(:site)                  { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:benefit_sponsor)       { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }

    context 'with valid input params' do
      let(:input_params) do
        {
          uri: uri,
          s3_reference_key: 'sample-key', bucket_name: bucket_name, employer_profile_id: benefit_sponsor.profiles.first.id, extension: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        }
      end
    end
  end
end