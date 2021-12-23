# Run this with RAILS_ENV=production bundle exec rake migrations:fix_nil_ethnicity_arrays
namespace :migrations do
  desc "Remove nils from person and applicant ethnicity arrays"
  task :fix_nil_ethnicity_arrays => :environment do |_task, _args|
    # - find draft applications that were ingested via ATP
    # - check and update person ethnicity array
    # - check and update applicant ethnicity array

    def find_person(person_hbx_id)
      Person.find_by(hbx_id: person_hbx_id)
    rescue StandardError => e
      puts "Error finding person document"
    end

    def fix_person_ethnicity_array(ethnicities, application, person)
      compact_ethnicities = ethnicities.compact
      Person.skip_callback(:update, :after, :person_create_or_update_handler)
      person.ethnicity = compact_ethnicities
      updated = person.save(validate: false)
      Person.set_callback(:update, :after, :person_create_or_update_handler)
      raise StandardError, "Failed to save person (hbx_id): #{person.hbx_id}" unless updated
      puts "APPLICATION: #{application.id} - updated person (hbx_id): #{person.hbx_id}"
    rescue StandardError => e
      puts "Error updating peson ethnicity array - #{e}"
    end

    def fix_applicant_ethnicity_array(ethnicities, application, applicant)
      compact_ethnicities = ethnicities.compact
      ::FinancialAssistance::Applicant.skip_callback(:update, :after, :propagate_applicant)
      applicant.ethnicity = compact_ethnicities
      updated = applicant.save(validate: false)
      ::FinancialAssistance::Applicant.set_callback(:update, :after, :propagate_applicant)
      raise StandardError, "Failed to save applicant (person_hbx_id): #{applicant.person_hbx_id}" unless updated
      puts "APPLICATION: #{application.id} - updated applicant (person_hbx_id): #{applicant.person_hbx_id}"
    rescue StandardError => e
      puts "Error updating applicant ethnicity array - #{e}"
    end

    applications = FinancialAssistance::Application.draft.not.where(transfer_id: nil)
    applications.no_timeout.each do |application|
      application.applicants.no_timeout.each do |applicant|
        person = find_person(applicant.person_hbx_id)
        next if person.nil?
        person_ethnicity = person.ethnicity
        applicant_ethnicity = applicant.ethnicity
        next unless person_ethnicity && person_ethnicity.include?(nil)
        fix_person_ethnicity_array(person_ethnicity, application, person)
        next unless applicant_ethnicity && applicant_ethnicity.include?(nil)
        fix_applicant_ethnicity_array(applicant_ethnicity, application, applicant)
      end
    end
  end
end