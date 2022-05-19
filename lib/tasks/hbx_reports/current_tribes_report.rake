require 'csv'

namespace :reports do

    desc "List of all current tribes"
    task :current_tribes_report => :environment do

        field_names  = %w(
            Primary_HBX_ID
            HBX_ID
            Tribal_ID
            Tribal_Name
            )

        file_name = "#{Rails.root}/public/current_tribes_report_#{Date.today.strftime('%m_%d_%Y')}.csv"

        CSV.open(file_name, "w", force_quotes: true) do |csv|
            csv << field_names
            applications = FinancialAssistance::Application.all
            applications.each do |application|
                tribe_applicants = application.applicants.where(:tribal_id.nin => [nil, ''])
                tribe_applicants.each do |applicant|
                    csv << [application&.primary_applicant&.person_hbx_id, 
                            application.hbx_id, 
                            applicant.tribal_id, 
                            applicant.tribal_name]
                end
            end
            
        end
    end
end