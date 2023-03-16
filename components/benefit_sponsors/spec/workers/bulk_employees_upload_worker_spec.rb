# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'
Sidekiq::Testing.inline!
# BenefitSponsors
module BenefitSponsors
  RSpec.describe BulkEmployeesUploadWorker, :dbclean => :after_each do
    describe "#perform" do
      let(:current_user) { FactoryBot.create :user }
      let(:file) do
        test_file = Rack::Test::UploadedFile.new(Rails.root.join("spec", "test_data", "census_employee_import", "DCHL Employee Census.xlsx"))
        test_file.content_type = 'application/xlsx'
        test_file
      end
      let(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let(:benefit_sponsor) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let(:employer_profile)      { benefit_sponsor.employer_profile }
      let(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
      context 'when a correct format is uploaded' do
        before do
          new_file = File.join("#{Rails.root}/public", "DCHL Employee Census.xlsx")
          FileUtils.cp Rails.root.join("spec", "test_data", "census_employee_import", "DCHL Employee Census.xlsx"), new_file
          benefit_sponsorship.save!
          BenefitSponsors::BulkEmployeesUploadWorker.perform_async('DCHL Employee Census.xlsx', 'application/xlsx', benefit_sponsor.profiles.first.id, current_user.email)

        end

        it "creates employees from a CSV file" do
          expect(CensusEmployee.count).to eq(1)
        end
      end

      context 'when a wrong file is uploaded' do
        before do
          new_file = File.join("#{Rails.root}/public", "individual.xlsx")
          FileUtils.cp Rails.root.join("spec", "test_data", "census_employee_import", "individual.xlsx"), new_file
          benefit_sponsorship.save!
          BenefitSponsors::BulkEmployeesUploadWorker.perform_async('individual.xlsx', 'application/xlsx', benefit_sponsor.profiles.first.id, current_user.email)
        end

        it 'should throw error' do
          expect(CensusEmployee.count).to eq(0)
        end
      end
    end
  end
end