# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::BenefitSponsors::EmployerProfile::BulkCeUpload, type: :model, dbclean: :after_each do

  describe '#call' do
    let(:bucket_name) { 'ce-roster-upload' }
    let(:s3_uri) { "f55679fe-34ca-426c-b68b-d5d92f16255c" }
    let(:filename) { "test.xlsx" }
    let(:bucket_name) { 'ce-roster-upload' }
    let(:person) { FactoryBot.create(:person) }
    let!(:site)                  { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:benefit_sponsor)       { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)      { benefit_sponsor.employer_profile }
    let!(:rating_area)           { FactoryBot.create_default :benefit_markets_locations_rating_area }
    let!(:service_area)          { FactoryBot.create_default :benefit_markets_locations_service_area }
    let(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
    let(:hired_on) {TimeKeeper.date_of_record.beginning_of_month}
    let!(:census_employees) {FactoryBot.create_list(:benefit_sponsors_census_employee, 2, :owner, employer_profile: employer_profile, benefit_sponsorship: benefit_sponsorship) }
    let(:input_params) do
      {
        s3_reference_key: 'sample-key', bucket_name: bucket_name, employer_profile_id: employer_profile.id, filename: filename, uri: s3_uri
      }
    end

    context "validate params" do
      context 'with invalid input params' do
        it "missing input params" do
          result = subject.call({})
          expect(result.failure).to eq ["uri is missing", "employer profile id is missing", "file name is missing"]
        end
      end

      context 'with valid input params' do
        before do
          s3_object = instance_double(Aws::S3Storage)
          allow(Aws::S3Storage).to receive(:find).with(s3_uri).and_return(s3_object)
          roster_upload_form = instance_double(::BenefitSponsors::Forms::RosterUploadForm)
          allow(::BenefitSponsors::Forms::RosterUploadForm).to receive(:call).with(any_args).and_return(roster_upload_form)
          allow(roster_upload_form).to receive(:save).and_return(true)
          allow(roster_upload_form).to receive(:census_records).and_return(census_employees)
        end
        it 'process the file and uploads census employees successfully' do
          result = subject.call(input_params)
          expect(employer_profile.census_employees.length).to eq 2
          expect(result.success).to match(/Successfully uploaded census employees: 2 to the roster/)
        end
      end
    end
  end
end
