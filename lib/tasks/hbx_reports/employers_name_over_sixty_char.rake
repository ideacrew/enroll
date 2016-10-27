require 'csv'

namespace :reports do
  namespace :shop do

    desc "Employer's  account with over 60 characters"
    task :employer_list => :environment do
      # collecting all the employers list and comparing with glue DB
      organizations = Organization.where(:'employer_profile'.exists=>true)

      field_names  = %w(
          hbx_id
          legal_name
          dba
          fein

        )
      processed_count = 0

      Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
      file_name = "#{Rails.root}/hbx_report/employers_name_over_sixty.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        organizations.each do |organization|

          csv << [
              organization.hbx_id
              organization.legal_name,
              organization.dba,
              organization.fein,
         ]
        end
        processed_count += 1
      end
      puts "List of all the employers #{file_name}"
    end
  end
end