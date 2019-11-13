# frozen_string_literal: true

# RAILS_ENV=production bundle exec rake reports:generate_report_for_invalid_families
require 'rake'
namespace :reports do

  desc 'List of families which fails document level validation'
  task generate_report_for_invalid_families: :environment do

    file_name = "#{Rails.root}/report_for_invalid_families_#{TimeKeeper.date_of_record.strftime('%Y-%m-%d')}.csv"
    field_names = %w[FamilyID ECaseID PrimaryHbxID PersonFullName ErrorReason]
    CSV.open(file_name, 'w', force_quotes: true) do |csv|
      csv << field_names
      @total_invalid_families = 0
      @duplicate_family_member_families = 0
      batch_size = 500
      offset = 0
      family_count = Family.count
      while offset < family_count
        Family.offset(offset).limit(batch_size).each do |family|
          begin
            family.save!
          rescue => e
            begin
              @total_invalid_families += 1
              error_reason = e.summary
              # Remove below line to get the full list of all invalid families.
              next family unless error_reason.to_s =~ /Family members Duplicate family_members for person/i

              @duplicate_family_member_families += 1
              person = family.primary_person
              error_reason.slice!('The following errors were found: ')
              e_case_id = family.has_valid_e_case_id? ? family.e_case_id.split('#').last : 'N/A'
              csv << [family.id, e_case_id, person.hbx_id, person.full_name, error_reason]
            rescue => error
              puts "Error: #{error.message}, Family: #{family.id}"
            end
          end
        end
        offset += batch_size
      end

      puts "Total number of invalid families: #{@total_invalid_families}"
      puts "Total number of invalid families with Duplicate Family Members issue: #{@duplicate_family_member_families}"
    end
  end
end
