#RAILS_ENV=production bundle exec rake reports:consumers_with_outstanding_verification_and_coverage_selected_report
require 'csv'
namespace :reports do
  desc 'List of people with consumer role and in verifcation outstanding with coverage selected'
  task consumers_with_outstanding_verification_and_coverage_selected_report: :environment do
    file_name = "#{Rails.root}/consumers_with_outstanding_verification_and_coverage_selected_report.csv"
    field_names  = %w(
                      Person_Hbx_id
                      Enrollment_id
                     )
    count = 0                 

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names
      people = Person.all_consumer_roles.where(:"consumer_role.aasm_state" => "verification_outstanding")
      people.each do |person|
        begin
              household = person.primary_family.active_household if person.primary_family.present?
              enrollments = household.hbx_enrollments.individual_market.where(:aasm_state => "coverage_selected", :effective_on => { :"$gte" => TimeKeeper.date_of_record.beginning_of_year, :"$lte" =>  TimeKeeper.date_of_record.end_of_year }) if person.primary_family.present?
              next if enrollments.nil?
              req_enrollments = enrollments.each do |enrollment|
                csv << [person.hbx_id,
                        enrollment.hbx_id]
              end
              count += 1 if enrollments.present?
        rescue => e
          puts "Bad person record, error: #{e}" unless Rails.env.test?
        end
      end
    end
    puts "Generated report with #{count} consumers" 
  end
end

            
