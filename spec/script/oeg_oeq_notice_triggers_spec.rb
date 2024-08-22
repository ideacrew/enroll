# frozen_string_literal: true

require 'rails_helper'

describe 'OEQ & OEG notice triggers script', dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  let(:primary) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:family)  { FactoryBot.create(:family, :with_primary_family_member, person: primary) }
  let!(:application) do
    FactoryBot.create(:financial_assistance_application,
                      family_id: family.id,
                      account_transferred: false,
                      transfer_requested: true,
                      assistance_year: TimeKeeper.date_of_record.next_year.year,
                      aasm_state: 'applicants_update_required',
                      hbx_id: "830293",
                      submitted_at: Date.yesterday,
                      created_at: Date.yesterday)
  end
  let!(:applicant) do
    applicant = FactoryBot.create(:applicant,
                                  first_name: primary.first_name,
                                  last_name: primary.last_name,
                                  dob: primary.dob,
                                  gender: primary.gender,
                                  application: application,
                                  ethnicity: [])
    applicant
  end

  let(:ivl_enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      :individual_unassisted,
      :with_product,
      aasm_state: "coverage_selected",
      effective_on: TimeKeeper.date_of_record.beginning_of_year,
      household: family.households.first,
      family: family,
      coverage_kind: 'health'
    )
  end

  let(:shop_enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      :shop,
      :with_product,
      aasm_state: "coverage_enrolled",
      effective_on: TimeKeeper.date_of_record.beginning_of_year,
      household: family.households.first,
      family: family,
      coverage_kind: 'health'
    )
  end

  before :each do
    Dir.glob("#{Rails.root}/log/oeg_oeq_notice_triggers_*.log").each do |file|
      FileUtils.rm(file)
    end
  end

  context "IVL enrolled family" do
    it 'triggers OEG/OEQ notice event' do
      ivl_enrollment
      load_script
      log_file_path = "#{Rails.root}/log/oeg_oeq_notice_triggers_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"

      expect(File.exist?(log_file_path)).to eq true
      expect(File.read(log_file_path)).to include("Total number of families to trigger OEQ/OEG notices: 1")
    end
  end

  context "Employer enrolled family" do
    it 'should not trigger OEG/OEQ notice event' do
      shop_enrollment
      load_script
      log_file_path = "#{Rails.root}/log/oeg_oeq_notice_triggers_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"

      expect(File.exist?(log_file_path)).to eq true
      expect(File.read(log_file_path)).to include("Total number of families to trigger OEQ/OEG notices: 0")
    end
  end

  def load_script
    load Rails.root.join('script/oeg_oeq_notice_triggers.rb')
  end
end
