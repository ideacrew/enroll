# Run this with RAILS_ENV=production bundle exec rake migrations:fix_nil_ethnicity_arrays application_hbx_id="12345"
# application_hbx_id is not required but can be used for testing/fixing on a single application.
# By default, rake will run on all ATP-ingested applications in a draft state
namespace :migrations do
  desc "Remove nils from person and applicant ethnicity arrays"
  task :fix_nil_ethnicity_arrays => :environment do |_task, _args|
    # - find draft applications that were ingested via ATP (or using provided hbx_id)
    # - check and update person ethnicity array
    # - check and update applicant ethnicity array

    def find_person(person_hbx_id)
      Person.find_by(hbx_id: person_hbx_id)
    rescue StandardError => e
      puts "Error finding person document - hbx_id: #{person_hbx_id}"
    end

    def fix_person_ethnicity_array(ethnicities, _application, person)
      Person.skip_callback(:update, :after, :person_create_or_update_handler)
      person.ethnicity = ethnicities.compact
      updated = person.save(validate: false)
      Person.set_callback(:update, :after, :person_create_or_update_handler)
      raise StandardError, "Failed to save person (hbx_id): #{person.hbx_id}" unless updated
    rescue StandardError => e
      puts "Error updating peson ethnicity array - #{e}"
    end

    def fix_applicant_ethnicity_array(ethnicities, application, applicant)
      ::FinancialAssistance::Applicant.skip_callback(:update, :after, :propagate_applicant)
      applicant.ethnicity = ethnicities.compact
      updated = applicant.save(validate: false)
      ::FinancialAssistance::Applicant.set_callback(:update, :after, :propagate_applicant)
      raise StandardError, "Failed to save applicant (person_hbx_id): #{applicant.person_hbx_id}" unless updated
      @primary_hbx_ids << application.primary_applicant&.person_hbx_id
    rescue StandardError => e
      puts "Error updating applicant ethnicity array - #{e}"
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
      @primary_hbx_ids = []
    # Fix person ethnicity arrays
      applications.no_timeout.each do |application|
        application.applicants.no_timeout.each do |applicant|
          person = find_person(applicant.person_hbx_id)
          next if person.nil?
          person_ethnicity = person.ethnicity
          next unless person_ethnicity && person_ethnicity.include?(nil)
          fix_person_ethnicity_array(person_ethnicity, application, person)
        end
      end
    # Fix applicant ethnicity arrays
      applications.no_timeout.each do |application|
        application.applicants.no_timeout.each do |applicant|
          next if applicant.nil?
          applicant_ethnicity = applicant.ethnicity
          next unless applicant_ethnicity && applicant_ethnicity.include?(nil)
          fix_applicant_ethnicity_array(applicant_ethnicity, application, applicant)
        end
      end
    end    
    remove_ethnicity_nils

    puts "UPDATED APPLICATIONS (primary person_hbx_id):"
    puts @primary_hbx_ids.uniq
  end
end
