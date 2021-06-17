# frozen_string_literal: true

require File.join(Rails.root, 'app/data_migrations/golden_seed_helper')
require File.join(Rails.root, 'app/data_migrations/golden_seed_financial_assistance_helper') if EnrollRegistry.feature_enabled?(:financial_assistance)

# Concern to keep some clutter after the row worker files
# Essentially mirrors the golden seed rake tasks
# TBD if we should move some of thoses helpers out of data migrations
module GoldenSeedWorkerConcern
  extend ActiveSupport::Concern
  include GoldenSeedHelper
  include GoldenSeedFinancialAssistanceHelper if EnrollRegistry.feature_enabled?(:financial_assistance)

  included do

    # Row data needs to be hash
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metriics/MethodLength
    def process_row(target_row)
      target_seed = target_row.seed
      row_data = target_row.data
      # remove_golden_seed_callbacks
      # TODO: Weird behavior. Prevents the original hash on the row attribute from being modified
      data_to_process = row_data.deep_dup.with_indifferent_access
      primary_family_for_current_case = target_seed.rows.where(unique_row_identifier: data_to_process[:case_name]).first&.target_record
      fa_enabled_and_required_for_case = EnrollRegistry.feature_enabled?(:financial_assistance) &&
                                         row_data['help_paying_for_coverage']
      # Just using this structure since it was used in the original golden seed
      target_row_data = {
        person_attributes: data_to_process
      }
      # Dependent
      if primary_family_for_current_case.present?
        target_row_data.merge!(
          {
            primary_person_record: primary_family_for_current_case.primary_person,
            family_record: primary_family_for_current_case
          }
        ).with_indifferent_access
        puts("Beginning to create dependent record for #{target_row_data[:person_attributes]['case_name']}")
        current_target_person = generate_and_return_dependent_record(target_row_data)
        target_row_data[:person_attributes].merge!(current_target_person: current_target_person)
        if fa_enabled_and_required_for_case
          current_fa_application = FinancialAssistance::Application.where(family_id: primary_family_for_current_case.id.to_s).first
          target_row_data[:fa_application] = current_fa_application
          puts("Beginning to create FA Applicant record for #{target_row_data[:person_attributes]['case_name']}")
          applicant_record = create_and_return_fa_applicant(target_row_data)
          target_row_data[:target_fa_applicant] = applicant_record
          add_applicant_income(target_row_data)
          add_applicant_addresses(target_row_data)
          add_applicant_phones(target_row_data)
          add_applicant_emails(target_row_data)
          add_applicant_income_response(target_row_data)
          add_applicant_mec_response(target_row_data)
        end
      # Primary person
      else
        puts("Beginning to create records for consumer role record for #{target_row_data[:person_attributes]['case_name']}")
        consumer_hash = create_and_return_matched_consumer_and_hash(target_row_data)
        target_row_data[:person_attributes][:current_target_person] = consumer_hash[:primary_person_record]
        puts("Beginning to create HBX Enrollment record for #{target_row_data[:person_attributes]['case_name']}")
        generate_and_return_hbx_enrollment(target_row_data)
        if fa_enabled_and_required_for_case
          puts("Beginning to create Financial Assisstance application record for #{target_row_data[:person_attributes]['case_name']}")
          application = create_and_return_fa_application(target_row_data)
          target_row_data[:fa_application] = application
          applicant_record = create_and_return_fa_applicant(target_row_data, true)
          target_row_data[:target_fa_applicant] = applicant_record
          add_applicant_income(target_row_data)
        end
      end
      # reinstate_golden_seed_callbacks
      target_row.update_attributes(
        unique_row_identifier: target_row_data[:person_attributes]["case_name"],
        record_id: target_row_data[:family_record]._id.to_s,
        record_class_name: "Family",
        seeded_at: DateTime.now
      )
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metriics/MethodLength
  end
end
