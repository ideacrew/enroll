require File.join(Rails.root, 'app/data_migrations/golden_seed_helper')
require File.join(Rails.root, 'app/data_migrations/golden_seed_financial_assistance_helper') if EnrollRegistry.feature_enabled?(:financial_assistance)

# Concern to keep some clutter after the row worker files
# Essentially mirrors the golden seed rake tasks
# TBD if we should move some of thoses helpers out of data migrations
module GoldenSeedWorkerConcern
  extend ActiveSupport::Concern

  included do

    # after_initialize do |instance|
    # end

    def find_seed_primary_person_record

    end

    def find_seed_family_record

    end
    
    # Row data needs to be hash
    def process_row(row_data)
      remove_golden_seed_callbacks
      
      # TODO: Need to figure out how to get the primary family ID.
      # Probably we'll have to set the primary person when they're created to be associated with a seed
      # and then query that seed
      # primary_family_for_current_case = case_collection[person_attributes["case_name"]]&.dig(:family_record)
      primary_family_for_current_case = nil
      fa_enabled_and_required_for_case = EnrollRegistry.feature_enabled?(:financial_assistance) &&
                                         person_attributes['help_paying_for_coverage']
      # Dependent
      if primary_family_for_current_case.present?
        row_data.merge!(
          {
            primary_person_record: nil,# Need to calculate this,
            family_record: nil, # need to calculate this
          }
        ).with_indifferent_access
        puts("Beginning to create dependent record for #{person_attributes['case_name']}") unless Rails.env.test?
        dependent_record = generate_and_return_dependent_record(row_data)
        if fa_enabled_and_required_for_case
          puts("Beginning to create FA Applicant record for #{person_attributes['case_name']}") unless Rails.env.test?
          add_applicant_income(row_data)
          add_applicant_addresses(row_data)
          add_applicant_phones(row_data)
          add_applicant_emails(row_data)
          add_applicant_income_response(row_data)
          add_applicant_mec_response(row_data)
        end
      else
        puts("Beginning to create records for consumer role record for #{person_attributes['case_name']}") unless Rails.env.test?
        case_collection[person_attributes["case_name"]] = create_and_return_matched_consumer_and_hash(row_data)
        puts("Beginning to create HBX Enrollment record for #{person_attributes['case_name']}") unless Rails.env.test?
        generate_and_return_hbx_enrollment(row_data)
        if fa_enabled_and_required_for_case
          puts("Beginning to create Financial Assisstance application record for #{person_attributes['case_name']}") unless Rails.env.test?
          application = create_and_return_fa_application(row_data)
          applicant_record = create_and_return_fa_applicant(row_data, true)
          add_applicant_income(row_data)
        end
      end
      reinstate_golden_seed_callbacks
    end
  end
end
