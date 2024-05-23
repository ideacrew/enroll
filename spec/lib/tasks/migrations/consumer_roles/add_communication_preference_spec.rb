# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Adds missing communication preference', :type => :task, dbclean: :around_each do
  before :all do
    Rake.application.rake_require 'tasks/migrations/add_communication_preference'
    Rake::Task.define_task(:environment)
  end

  after :all do
    [
      "#{Rails.root}/log/add_missing_communication_preference.log",
      "#{Rails.root}/primary_people_with_updated_contact_method.csv"
    ].each do |file_name|
      next unless File.exist?(file_name)

      FileUtils.rm_rf(file_name)
    end

    DatabaseCleaner.clean
  end

  let(:family) do
    FactoryBot.create(:family, :with_primary_family_member, person: primary_with_contact_method)
  end

  let(:family2) do
    FactoryBot.create(:family, :with_primary_family_member, person: primary_without_consumer_role)
  end

  let(:family3) do
    FactoryBot.create(:family, :with_primary_family_member, person: primary_without_contact_method)
  end

  let(:primary_with_contact_method) do
    FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, hbx_id: '12345678900')
  end
  let(:primary_without_consumer_role) { FactoryBot.create(:person, hbx_id: '12345678901') }

  let(:primary_without_contact_method) do
    per = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, hbx_id: '12345678902')
    role = per.consumer_role
    role.contact_method = nil
    role.save!
    role.reload.person
  end

  let(:current_application) { FactoryBot.create(:financial_assistance_application, family_id: family3.id) }
  let(:current_applicant) do
    FactoryBot.create(
      :financial_assistance_applicant,
      application: current_application,
      is_primary_applicant: true,
      person_hbx_id: primary_without_contact_method.hbx_id,
      family_member_id: family3.primary_applicant.id
    )
  end

  let(:renewal_application) do
    FactoryBot.create(
      :financial_assistance_application,
      family_id: family3.id,
      assistance_year: TimeKeeper.date_of_record.next_year.year
    )
  end

  let(:renewal_applicant) do
    FactoryBot.create(
      :financial_assistance_applicant,
      application: renewal_application,
      is_primary_applicant: true,
      person_hbx_id: primary_without_contact_method.hbx_id,
      family_member_id: family3.primary_applicant.id
    )
  end

  before do
    family
    family2
    family3
    current_applicant
    renewal_applicant
  end

  let(:consumer_role) { primary_without_contact_method.consumer_role }
  let(:contact_method_mail_only) { ::ConsumerRole::CONTACT_METHOD_MAPPING[['Mail']] }

  let(:csv_file_name) { "#{Rails.root}/primary_people_with_updated_contact_method.csv" }
  let(:csv_output) { CSV.read(csv_file_name, headers: true) }
  let(:logger_file_name) { "#{Rails.root}/log/add_missing_communication_preference.log" }
  let(:logger_output) { File.read(logger_file_name) }

  context 'when there is only one member per family' do
    it 'adds contact method, logs info and adds updates to CSV' do
      expect(consumer_role.contact_method).to be_nil
      invoke_migration_task
      expect(consumer_role.reload.contact_method).to eq(contact_method_mail_only)
      expect(csv_output.count).not_to be_zero
      expect(logger_output).to include("Total number of families to process:")
    end
  end

  context 'when the dependent does not have contact preference' do
    before do
      consumer_role.update!(contact_method: 'Only Electronic communications')
      invoke_migration_task
    end

    it 'skips the family' do
      expect(consumer_role.reload.contact_method).to eq('Only Electronic communications')
    end
  end
end

def invoke_migration_task
  Rake::Task['migrations:add_communication_preference'].reenable
  Rake::Task['migrations:add_communication_preference'].invoke
end
