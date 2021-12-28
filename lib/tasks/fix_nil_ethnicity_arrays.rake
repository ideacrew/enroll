# Run this with RAILS_ENV=production bundle exec rake migrations:fix_nil_ethnicity_arrays application_hbx_id="12345"
# application_hbx_id is not required but can be used for testing/fixing on a single application.
# By default, rake will run on all ATP-ingested applications in a draft state
namespace :migrations do
  desc "Remove nils from person and applicant ethnicity arrays"
  task :fix_nil_ethnicity_arrays => :environment do |_task, _args|
    # - find draft applications that were ingested via ATP (or using provided hbx_id)
    # - check and update person ethnicity arrays
    # - check and update applicant ethnicity arrays

    def find_person(person_hbx_id)
      Person.find_by(hbx_id: person_hbx_id)
    rescue StandardError => e
      ["Error finding person document - hbx_id: #{person_hbx_id}"]
    end

    def fix_person_ethnicity_array(ethnicities, application, person)
      primary = application.primary_applicant ? application.primary_applicant.person_hbx_id : "no_primary_found"
      result = [application.hbx_id, primary, person.hbx_id, person.ethnicity.to_s]
      Person.skip_callback(:update, :after, :person_create_or_update_handler)
      person.ethnicity = ethnicities.compact
      updated = person.save(validate: false)
      Person.set_callback(:update, :after, :person_create_or_update_handler)
      raise StandardError, "Failed to save person (hbx_id): #{person.hbx_id}" unless updated
      result << person.ethnicity.to_s
    rescue StandardError => e
      ["Error updating peson ethnicity array - #{e}"]
    end

    def fix_applicant_ethnicity_array(ethnicities, application, applicant)
      primary = application.primary_applicant ? application.primary_applicant.person_hbx_id : "no_primary_found"
      result = [application.hbx_id, primary, applicant.person_hbx_id, applicant.ethnicity.to_s]

      ::FinancialAssistance::Applicant.skip_callback(:update, :after, :propagate_applicant)
      applicant.ethnicity = ethnicities.compact
      updated = applicant.save(validate: false)
      ::FinancialAssistance::Applicant.set_callback(:update, :after, :propagate_applicant)
      raise StandardError, "Failed to save applicant (person_hbx_id): #{applicant.person_hbx_id}" unless updated
      result << applicant.ethnicity.to_s
    rescue StandardError => e
      ["Error updating applicant ethnicity array - #{e}"]
    end

    def remove_ethnicity_nils
      application_hbx_id = ENV['application_hbx_id']
      applications = if application_hbx_id.present?
                       # Run on application with provided hbx_id
                       FinancialAssistance::Application.draft.where(hbx_id: application_hbx_id)
                     else
                       # Run on all ATP-ingested draft applications
                       FinancialAssistance::Application.draft.not.where(transfer_id: nil)
                     end

    # Fix person ethnicity arrays
      puts "\nFinding person ethnicity arrays containing nil..."
      timestamp = Time.zone.now.strftime("%Y%m%d_%H%M%S")
      file_name = "#{Rails.root}/person_nil_ethnicity_#{timestamp}.csv"
      FileUtils.touch(file_name)
      CSV.open(file_name, 'w+', headers: true) do |csv|
        csv << %w[APPLICATION_HBX_ID PRIMARY_HBX_ID PERSON_HBX_ID INITIAL_ETHNICITY UPDATED_ETHNICIY]
        applications.no_timeout.each do |application|
          application.applicants.no_timeout.each do |applicant|
            person = find_person(applicant.person_hbx_id)
            if person.is_a? Array
              puts person
              csv << person
              next
            end
            person_ethnicity = person.ethnicity
            next unless person_ethnicity && person_ethnicity.include?(nil)
            puts "Removing ethnicity nil(s) from person #{person.hbx_id}"
            csv << fix_person_ethnicity_array(person_ethnicity, application, person)
          end
        end
      end

    # Fix applicant ethnicity arrays
      puts "\nFinding applicant ethnicity arrays containing nil..."
      timestamp = Time.zone.now.strftime("%Y%m%d_%H%M%S")
      file_name = "#{Rails.root}/applicant_nil_ethnicity_#{timestamp}.csv"
      FileUtils.touch(file_name)
      CSV.open(file_name, 'w+', headers: true) do |csv|
        csv << %w[APPLICATION_HBX_ID PRIMARY_HBX_ID PERSON_HBX_ID INITIAL_ETHNICITY UPDATED_ETHNICIY]
        applications.no_timeout.each do |application|
          application.applicants.no_timeout.each do |applicant|
            next if applicant.nil?
            applicant_ethnicity = applicant.ethnicity
            next unless applicant_ethnicity && applicant_ethnicity.include?(nil)
            puts "Removing ethnicity nil(s) from applicant #{applicant.person_hbx_id}"
            csv << fix_applicant_ethnicity_array(applicant_ethnicity, application, applicant)
          end
        end
      end
    end
    remove_ethnicity_nils
    puts "Nil ethnicity fix complete"
  end
end
