# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# This class to update yearly_expected_contribution for 2022 active determinations
# This migration is specific for state of State
class UpdateExpectedContributionFor2022ActiveDeterminations < MongoidMigrationTask

  def update_tax_households(family, eligibility, yearly_expected_contribution)
    active_thh = family.active_household.tax_households.active_tax_household.detect do |thh|
      (eligibility.applicants.map(&:person_hbx_id) & thh.tax_household_members.map(&:person).flat_map(&:hbx_id)).present?
    end
    return unless active_thh&.yearly_expected_contribution&.zero?

    active_thh.update_attributes!(yearly_expected_contribution: yearly_expected_contribution)
  end

  def update_eligibility_determination(application, ed_hbx_assigned_id, yearly_expected_contribution)
    eligibility = application.eligibility_determinations.where(hbx_assigned_id: ed_hbx_assigned_id).first
    return eligibility unless eligibility&.yearly_expected_contribution&.zero?

    eligibility.update_attributes!(yearly_expected_contribution: yearly_expected_contribution)
    eligibility
  end

  def add_expected_contribution(thhs_information, application, family)
    thhs_information.each do |ed_hbx_assigned_id, yearly_expected_contribution|
      eligibility = update_eligibility_determination(application, ed_hbx_assigned_id, yearly_expected_contribution)
      update_tax_households(family, eligibility, yearly_expected_contribution)
    end
  end

  def read_and_add_expected_contribution(field_names, file_name, source_file)
    CSV.open(file_name, 'w', force_quotes: true) do |csv|
      csv << field_names

      CSV.foreach(source_file, headers: true) do |row|
        application = FinancialAssistance::Application.where(hbx_id: row['ApplicationHbxID']).first
        next row if application.blank?
        family = application.family
        thhs_information = JSON.parse(row['AptcHouseholdsWithYearlyExpectedContribution'])
        add_expected_contribution(thhs_information, application, family)
        csv << [family.primary_person.hbx_id, family.hbx_assigned_id, row['ApplicationHbxID']]
      rescue StandardError => e
        puts "Unable to process ApplicationHbxID: #{row['ApplicationHbxID']}, message: #{e.message}, backtrace: #{e.backtrace}"
      end
    end
  end

  def migrate
    field_names = %w[PrimaryPersonHbxID FamilyHbxAssignedId ApplicationHbxID]
    file_name = "#{Rails.root}/list_of_applications_with_updated_expected_contribution.csv"
    source_file = "#{Rails.root}/applications_with_yearly_expected_contributions_for_aptc_households.csv"

    unless File.exist?(source_file)
      puts "Cannot find file: #{source_file}"
      return
    end

    read_and_add_expected_contribution(field_names, file_name, source_file)
  end
end
