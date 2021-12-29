# Run this with RAILS_ENV=production bundle exec rake migrations:identify_nil_ethnicity_arrays
# By default, rake will run on all ATP-ingested applications in a draft state
namespace :migrations do
  desc "Identify person and applicant ethnicity arrays containing nils"
  task :identify_nil_ethnicity_arrays => :environment do |_task, _args|
    # - find draft applications that were ingested via ATP
    # - check and report person ethnicity arrays
    # - check and report applicant ethnicity arrays

    def find_person(person_hbx_id)
      Person.where(hbx_id: person_hbx_id).first
    end

    def find_ethnicity_nils
      applications = FinancialAssistance::Application.draft.where(:transfer_id.nin => [nil, ''])

    # Find person ethnicity arrays
      puts "\nFinding person ethnicity arrays containing nil..."
      timestamp = Time.zone.now.strftime("%Y%m%d_%H%M%S")
      file_name = "#{Rails.root}/person_nil_ethnicity_#{timestamp}.csv"
      FileUtils.touch(file_name)
      CSV.open(file_name, 'w+', headers: true) do |csv|
        csv << %w[APPLICATION_HBX_ID PRIMARY_HBX_ID PERSON_HBX_ID ETHNICITY]
        applications.no_timeout.each do |application|
          application.applicants.no_timeout.each do |applicant|
            person = find_person(applicant.person_hbx_id)
            if person
              person_ethnicity = person.ethnicity
              next unless person_ethnicity && person_ethnicity.include?(nil)
              primary = application.primary_applicant ? application.primary_applicant.person_hbx_id : "no_primary_found"
              csv << [application.hbx_id, primary, person.hbx_id, person.ethnicity.to_s]
            else
              puts "Error finding person document - hbx_id: #{person_hbx_id}"
            end
          end
        end
      end

    # Find applicant ethnicity arrays
      puts "\nFinding applicant ethnicity arrays containing nil..."
      timestamp = Time.zone.now.strftime("%Y%m%d_%H%M%S")
      file_name = "#{Rails.root}/applicant_nil_ethnicity_#{timestamp}.csv"
      FileUtils.touch(file_name)
      CSV.open(file_name, 'w+', headers: true) do |csv|
        csv << %w[APPLICATION_HBX_ID PRIMARY_HBX_ID PERSON_HBX_ID ETHNICITY]
        applications.no_timeout.each do |application|
          application.applicants.no_timeout.each do |applicant|
            next if applicant.nil?
            applicant_ethnicity = applicant.ethnicity
            next unless applicant_ethnicity && applicant_ethnicity.include?(nil)
            primary = application.primary_applicant ? application.primary_applicant.person_hbx_id : "no_primary_found"
            csv << [application.hbx_id, primary, applicant.person_hbx_id, applicant.ethnicity.to_s]
          end
        end
      end
    end
    find_ethnicity_nils
    puts "Find nil ethnicity arrays complete"
  end
end
