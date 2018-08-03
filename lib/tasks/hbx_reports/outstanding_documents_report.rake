require 'rake'
require "#{Rails.root}/lib/documents_verification_status"
require "#{Rails.root}/app/helpers/verification_helper"
include VerificationHelper
# This is a report that is generated for audit purpose, for all families with outstanding documents
# The task to run is RAILS_ENV=production bundle exec rake reports:outstanding_documents_list

namespace :reports do

  desc 'List of outstanding documents of families'
  task outstanding_documents_list: :environment do
    count = 0
    families = Family.outstanding_verification
    if families.present?
      file_name = "#{Rails.root}/public/outstanding_documents_report_#{TimeKeeper.date_of_record.strftime('%Y-%m-%d')}.csv"
      CSV.open(file_name, 'w', force_quotes: true) do |csv|
        csv << %w[HBX_ID First_Name Last_Name Number_of_Documents Due_Date DC_Residency Citizenship Social_Security_Number American_Indian/Alaskan_Native Immigration_Status]
        families.each do |family|
          family.family_members.each do |family_member|
            if family.enrolled_policy(family_member).present? # checking whether the family_member is present on enrollment or not
              person = family_member.person
              document_count = person.consumer_role.vlp_documents.select{|doc| doc.identifier}.count
              min_verification_due_date = family.best_verification_due_date
              calculate_due_date(family, family_member)
              csv << [person.hbx_id,
                      person.first_name,
                      person.last_name,
                      document_count,
                      min_verification_due_date,
                      @residency_due_date,
                      @citizenship_due_date,
                      @ssn_due_date,
                      @ami_due_date,
                      @immigration_due_date]
            end
          end
          count += 1
        end
        puts "File path: %s. Total count of families with outstanding documents: #{count}"
      end
    else
      puts 'Families with outstanding documents does not exist.. Quitting Rake Task!!'
    end
  end

  def calculate_due_date(family, family_member)
    @citizenship_due_date = @ssn_due_date = @ami_due_date = @immigration_due_date = @residency_due_date = nil
    family_member.person.verification_types.each do |v_type|
      doc_due_date = family.document_due_date(family_member, v_type)
      due_date = doc_due_date.present? ? doc_due_date.to_date : nil
      case v_type
        when 'DC Residency'
          @residency_due_date = due_date
        when 'Citizenship'
          @citizenship_due_date = due_date
        when 'Social Security Number'
          @ssn_due_date = due_date
        when 'American Indian Status'
          @ami_due_date = due_date
        when 'Immigration status'
          @immigration_due_date = due_date
      end
    end
  end

end
