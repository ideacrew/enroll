require 'csv'
namespace :reports do
  namespace :shop do
    # Following task will generate daily report with terminated benefit applications
    # RAILS_ENV=production bundle exec rake reports:shop:benefit_application_terminated_list['termination_date']
    # RAILS_ENV=production bundle exec rake reports:shop:benefit_application_terminated_list['02/01/2017']

    desc "Report of Benefit Applications Terminated"
    task :benefit_application_terminated_list, [:termination_date] => :environment do |task, args|
      include Config::AcaHelper

      window_date = Date.strptime(args[:termination_date], "%m/%d/%Y")

      valid_states = [:terminated, :termination_pending]
      terminated_sponsorships = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where({
        "benefit_applications" => {
          "$elemMatch" => {
            "terminated_on" => window_date,
            "aasm_state" => {"$in" => valid_states}
          }
        }
        })

        processed_count = 0
        file_name = fetch_file_format('benefit_application_terminated_list', 'BENEFITAPPLICATIONTERMINATEDLIST')
        field_names  = [ "FEIN", "Legal Name", "DBA", "AASM State", "Plan Year Effective Date", "OE Close Date", "Termination reason", "Termination Kind"]

        CSV.open(file_name, "w") do |csv|
          csv << field_names

          terminated_sponsorships.each do |terminated_sponsorship|
            begin
              employer_profile = terminated_sponsorship.profile
              benefit_applications = terminated_sponsorship.benefit_applications.benefit_terminate_on(window_date)
              benefit_applications.each do |benefit_application|
                csv << [
                  employer_profile.fein,
                  employer_profile.legal_name,
                  employer_profile.dba,
                  benefit_application.aasm_state,
                  benefit_application.start_on.to_date.to_s,
                  benefit_application.open_enrollment_end_on.to_date.to_s,
                  benefit_application.termination_reason,
                  benefit_application.termination_kind
                ]
              end
            rescue Exception => e
              "Exception #{e}"
            end
            processed_count += 1
          end
        end
        puts "For #{window_date}, #{processed_count} benefit application terminations output to file: #{file_name}"
      end
    end
  end
