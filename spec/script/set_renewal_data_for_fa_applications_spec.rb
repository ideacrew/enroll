# frozen_string_literal: true

require 'rails_helper'

describe 'set_renewal_data_for_fa_applications' do
  before do
    DatabaseCleaner.clean
  end

  let!(:person) { FactoryBot.create(:person, :with_consumer_role, first_name: 'First', last_name: 'Last') }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id, years_to_renew: 5, is_renewal_authorized: true) }
  let!(:application2) do
    FactoryBot.create(:financial_assistance_application, family_id: family.id, aasm_state: ['draft', 'renewal_draft', 'submission_pending'].sample)
  end
  let!(:applicant) do
    FactoryBot.create(:applicant,
                      application: application,
                      dob: person.dob,
                      first_name: person.first_name,
                      last_name: person.last_name,
                      is_primary_applicant: true,
                      person_hbx_id: person.hbx_id,
                      family_member_id: family.primary_applicant.id)
  end

  before :each do
    invoke_set_renewal_data_for_fa_applications_script
    @csv_file_content = CSV.read("#{Rails.root}/set_renewal_data_for_fa_applications_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv")
  end

  it 'should add data to the file' do
    expect(@csv_file_content.size).to be > 1
  end

  it "should match with the applicant's person_hbx_id" do
    expect(@csv_file_content[1][0]).to eq(applicant.person_hbx_id)
  end

  it "should match with the applicant's full_name" do
    expect(@csv_file_content[1][1]).to eq(applicant.full_name)
  end

  it "should match with the application's hbx_id" do
    expect(@csv_file_content[1][2]).to eq(application.hbx_id)
  end

  it "should match with the application's aasm_state" do
    expect(@csv_file_content[1][3]).to eq(application.aasm_state)
  end

  it "should match with the application's is_renewal_authorized" do
    expect(@csv_file_content[1][4]).to eq(application.is_renewal_authorized.to_s)
  end

  it 'should set renewal_base_year for application' do
    expect(@csv_file_content[1][5]).to eq(application.send(:calculate_renewal_base_year).to_s)
  end

  it "should match with the application's years_to_renew" do
    expect(@csv_file_content[1][6]).to eq(application.years_to_renew.to_s)
  end

  # Checks to confirm that application2 is not included in the output CSV.
  it 'should not include application2 in the report as it is a wip application' do
    expect(@csv_file_content.flatten).not_to include(application2.hbx_id.to_s)
  end

  after :each do
    FileUtils.rm_rf("#{Rails.root}/set_renewal_data_for_fa_applications_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv")
    FileUtils.rm_rf("#{Rails.root}/log/set_renewal_data_for_fa_applications_logger.log")
  end
end

def invoke_set_renewal_data_for_fa_applications_script
  script_file = File.join(Rails.root, '/script/set_renewal_data_for_fa_applications.rb')
  load script_file
end
