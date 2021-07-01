# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')
require File.join(Rails.root, 'app/data_migrations/golden_seed_helper')
require File.join(Rails.root, 'app/data_migrations/golden_seed_financial_assistance_helper')


# This class will, with either a specific spreadsheet or independently:
# 1) Create a site with HBX/profile and empty benefit market if the site is blank.
#    It should work for any client (DC, ME, MA), because the ::BenefitSponsors::SiteSpecHelpers files have
#    been refactored to accommodate those.
# 2) Create fully matched consumer records and dependents. Their names will appear in the rake output.
# 3) Create an HbxEnrollment for each of those consumers, with an existing random IVL product OR a create a new one
# Notes:
# A) After running this rake task, you should be able to log in to the environment as a super admin, go to the HbxAdmin
# section, click the "Families" tab, and click one of the consumers, and see their current selected coverage.
# B) This rake task is designed to be "non intrusive", meaning that it won't modify any existing data, and can also be
# ran from a blank database
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Metrics/MethodLength
# TODO: Need to find a solution like having multiple CSV's for the value of "NO DC Address"
# TODO: Currently commented out as of 6/10/21
# but add an ENV variable to avoid callbacks and only set HBX_ID callbacks at the end
class GoldenSeedIndividual < MongoidMigrationTask
  include GoldenSeedHelper
  include GoldenSeedFinancialAssistanceHelper

  attr_accessor :case_collection, :counter_number, :consumer_people_and_users, :original_person_hbx_ids, :original_enrollment_hbx_ids

  def migrate_with_csv
    ivl_csv = File.read(ivl_testbed_scenario_csv)
    puts("CSV #{ivl_testbed_scenario_csv} present for IVL Golden Seed, using CSV for seed.") unless Rails.env.test?
    CSV.parse(ivl_csv, :headers => true).each do |person_attributes|
      puts("Running for #{person_attributes['case_name']}") unless Rails.env.test?

      # person_attributes = person_attributes.to_h.with_indifferent_access
      primary_family_for_current_case = case_collection[person_attributes["case_name"]]&.dig(:family_record)
      fa_enabled_and_required_for_case = EnrollRegistry.feature_enabled?(:financial_assistance) &&
                                         person_attributes['help_paying_for_coverage']
      case_included_in_keys = case_collection.keys.include?(person_attributes["case_name"])
      case_collection[person_attributes["case_name"]] = {} if case_included_in_keys.blank?
      case_collection[person_attributes["case_name"]][:person_attributes] = person_attributes
      if case_collection[person_attributes["case_name"]] && primary_family_for_current_case.present?
        puts("Beginning to create dependent record for #{person_attributes['case_name']}") unless Rails.env.test?
        dependent_record = generate_and_return_dependent_record(case_collection[person_attributes["case_name"]])
        case_collection[person_attributes["case_name"]][:dependents] = [] if case_collection[person_attributes["case_name"]][:dependents].blank?
        case_collection[person_attributes["case_name"]][:dependents] << dependent_record
        case_collection[person_attributes["case_name"]][:person_attributes][:current_target_person] = dependent_record
        if fa_enabled_and_required_for_case
          puts("Beginning to create FA Applicant record for #{person_attributes['case_name']}") unless Rails.env.test?
          applicant_record = create_and_return_fa_applicant(case_collection[person_attributes["case_name"]])
          case_collection[person_attributes["case_name"]][:target_fa_applicant] = applicant_record
          case_collection[person_attributes["case_name"]][:fa_applicants] = [] unless case_collection[person_attributes["case_name"]][:applicants].is_a?(Array)
          case_collection[person_attributes["case_name"]][:fa_applicants] << {applicant_record: applicant_record, relationship_to_primary: person_attributes['relationship_to_primary']}
          case_info_hash = case_collection[person_attributes["case_name"]]
          add_applicant_income(case_info_hash)
          add_applicant_addresses(case_info_hash)
          add_applicant_phones(case_info_hash)
          add_applicant_emails(case_info_hash)
          add_applicant_income_response(case_info_hash)
          add_applicant_mec_response(case_info_hash)
        end
      else
        puts("Beginning to create records for consumer role record for #{person_attributes['case_name']}") unless Rails.env.test?
        case_collection[person_attributes["case_name"]] = create_and_return_matched_consumer_and_hash(
          case_collection[person_attributes["case_name"]]
        )
        consumer_people_and_users[case_collection[person_attributes["case_name"]][:primary_person_record].full_name] = case_collection[person_attributes["case_name"]][:user_record]
        puts("Beginning to create HBX Enrollment record for #{person_attributes['case_name']}") unless Rails.env.test?
        generate_and_return_hbx_enrollment(case_collection[person_attributes["case_name"]])
        case_collection[person_attributes["case_name"]][:person_attributes][:current_target_person] = case_collection[person_attributes["case_name"]][:primary_person_record]
        if fa_enabled_and_required_for_case
          puts("Beginning to create Financial Assisstance application record for #{person_attributes['case_name']}") unless Rails.env.test?
          application = create_and_return_fa_application(case_collection[person_attributes["case_name"]])
          case_collection[person_attributes["case_name"]][:fa_application] = application
          applicant_record = create_and_return_fa_applicant(case_collection[person_attributes["case_name"]], true)
          case_collection[person_attributes["case_name"]][:target_fa_applicant] = applicant_record
          case_collection[person_attributes["case_name"]][:fa_applicants] = [] unless case_collection[person_attributes["case_name"]][:applicants].is_a?(Array)
          case_collection[person_attributes["case_name"]][:fa_applicants] << {applicant_record: applicant_record, relationship_to_primary: person_attributes['relationship_to_primary']}
          add_applicant_income(case_collection[person_attributes["case_name"]])
        end
      end
      @counter_number += 1
    end
    # These are used if you want to remove callbacks on hbx ids
    # update_person_hbx_ids
    # update_enrollment_hbx_ids
    return unless EnrollRegistry.feature_enabled?(:financial_assistance)
    unless Rails.env.test?
      puts(
        "Family and Financial Assistance set up complete."\
        " Creating relationships and then submitting all FA applications"
      )
    end
    case_collection.each do |case_array|
      next unless case_array[1][:fa_application]
      puts("Beginning to create FA relationships records") unless Rails.env.test?
      create_fa_relationships(case_array)
      # TODO: We will submit later
      # puts("Submitting financial assistance application.") unless Rails.env.test?
      # case_array[1][:fa_application].submit!
    end
  end

  def migrate_without_csv
    5.times do
      consumer_attributes = {
        person_attributes: {
          relationship_to_primary: 'self',
          is_primary_applicant?: true
        }
      }.with_indifferent_access
      consumer_hash = create_and_return_matched_consumer_and_hash(consumer_attributes)
      consumer_people_and_users[consumer_hash[:primary_person_record].full_name] = consumer_hash[:user_record]
      generate_and_return_hbx_enrollment(consumer_hash)
      ['spouse', 'child'].each do |relationship_to_primary|
        dependent_attributes = {
          primary_person_record: consumer_hash[:primary_person_record],
          family_record: consumer_hash[:family_record],
          person_attributes: {
            relationship_to_primary: relationship_to_primary
          }
        }.with_indifferent_access
        generate_and_return_dependent_record(dependent_attributes)
      end
      @counter_number += 1
    end
  end

  def migrate
    @case_collection = {}
    @counter_number = 0
    # @original_enrollment_hbx_ids = []
    # @original_person_hbx_ids = []
    puts('Executing Golden Seed IVL migration migration.') unless Rails.env.test?
    puts("Site present, using existing site.") if site.present? && !Rails.env.test?
    ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_empty_benefit_market if site.blank?
    ## What to do here? They don't seem to create products but they do in the cucumbers for shopping?
    puts("IVL products present in database, will use existing ones to create HbxEnrollments.") if ivl_products.present? && !Rails.env.test?
    create_and_return_service_area_and_product if ivl_products.blank?
    create_and_return_ivl_hbx_profile_and_sponsorship
    @consumer_people_and_users = {}
    remove_golden_seed_callbacks
    if ivl_testbed_scenario_csv
      migrate_with_csv
    else
      migrate_without_csv
    end
    reinstate_golden_seed_callbacks
    puts("Site present for: #{BenefitSponsors::Site.all.map(&:site_key)}") if BenefitSponsors::Site.present? && !Rails.env.test?
    puts("Golden Seed IVL migration complete. All consumer roles are:") unless Rails.env.test?
    consumer_people_and_users.each do |person_full_name, user_record|
      puts(person_full_name.to_s) unless Rails.env.test?
      if user_record.person.primary_family.family_members.count > 1
        puts("With enrollment with APTC present.") if user_record.person.primary_family.hbx_enrollments.detect { |enrollment| enrollment.applied_aptc_amount.present? }
        puts("With dependents:") unless Rails.env.test?
        dependent_names = user_record.person.primary_family.family_members.reject(&:is_primary_applicant?)
        dependent_names.each { |family_member| puts(family_member&.person&.full_name) unless Rails.env.test? }
      end
      # TODO: Refactor this to do lesss applicants, maybe only from this run
      # Maybe set it to a variable right when its created
      applicants = FinancialAssistance::Application.where(
        family_id: user_record&.person&.primary_family&.id&.to_s
      ).all.map(&:applicants).flatten
      if applicants.present?
        applicant_with_pregnancy = applicants.detect do |applicant|
          applicant.is_pregnant == true ||
            applicant.is_post_partum_period == true ||
            applicant.pregnancy_due_on.present?
        end
        puts("With pregnant family member applicant.") if applicant_with_pregnancy.present? && !Rails.env.test?
      end
      puts("With user #{user_record.email}") if user_record && !Rails.env.test?
    end
  end
end

# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/MethodLength

