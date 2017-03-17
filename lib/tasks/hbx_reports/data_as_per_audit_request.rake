require 'csv'
 # This is a report that generated for audit purpose, with IVL's not applied for assistance.
 # The task to run is RAILS_ENV=production bundle exec rake reports:audit_requested_list
namespace :reports do
 
  desc "List of unassisted IVL's registered in enroll from 10/12/2015 to 10/31/2016"
  task :audit_requested_list => :environment do

    start_date = Date.new(2015,10,12)
    end_date = Date.new(2016,9,30)

      field_names  = %w(
        FAMILY_ID
        HBX_ID
        Last_Name
        First_Name
        Full_Name
        Date_Of_Birth
        Relationship
        Application_Date
        Gender
        Primary_Applicant_Indicator
        Home_Address_line_1
        Home_Address_line_2
        Home_City
        Home_State
        Home_Zipcode
        Mailing_Address_line_1
        Mailing_Address_line_2
        Mailing_City
        Mailing_State
        Mailing_Zipcode
        Citizenship_Status
        Naturalized_Citizen
        Incarceration_Status
        American_Indian_Or_Alaska_Native
      )
     count = 0
     file_name = "#{Rails.root}/public/audit_request_data_report.csv"

    def submitted_application(person, start_date, end_date)
      person.addresses.present? && person.addresses[0].created_at >= start_date && person.addresses[0].created_at <= end_date
    end

    def select_versioned_person(person, start_date, end_date)
      person.citizen_status.present? && submitted_application(person, start_date, end_date)
    end

    def versioned_dependent(person)
      person.versions.detect { |ver| ver.citizen_status.present? } || person
    end

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names

      families = Family.where(:"created_at" => { "$gte" => start_date, "$lte" => end_date}, :"e_case_id" => nil)
      families.each do |family|
        begin
          primary_fm = family.primary_family_member
          next if primary_fm.person.user.blank?
          next if family.households.flat_map(&:hbx_enrollments).any? {|enr| enr.effective_on < Date.new(2016,1,1)}
          next if (primary_fm.person.consumer_role.blank? || primary_fm.person.consumer_role.vlp_authority == "curam" || (primary_fm.person.consumer_role.bookmark_url.to_s.include? "edit") || primary_fm.person.addresses.blank? )
          
          versioned_primary = primary_fm.person.versions.detect { |ver| select_versioned_person(ver, start_date, end_date) }
          versioned_primary = versioned_primary || primary_fm.person
          family.family_members.each do |fm|

            versioned_person = fm.is_primary_applicant ? versioned_primary : versioned_dependent(fm.person)

            begin
              mailing_address = versioned_person.addresses.detect { |adr| adr.kind == "mailing" }
              citizen_status = versioned_person.citizen_status.try(:humanize) || "No Info"
              naturalized_citizen = ::ConsumerRole::NATURALIZED_CITIZEN_STATUS.include?(versioned_person.citizen_status) if fm.person.citizen_status.present?
              tribe_member = ::ConsumerRole::INDIAN_TRIBE_MEMBER_STATUS.include?(versioned_person.citizen_status) if fm.person.citizen_status.present?

              csv << [
                fm.family.hbx_assigned_id,
                versioned_person.hbx_id,
                versioned_person.last_name,
                versioned_person.first_name,
                versioned_person.full_name,
                versioned_person.dob,
                fm.primary_relationship,
                fm.family.created_at,
                versioned_person.gender,
                fm.is_primary_applicant,
                versioned_person.home_address.try(:address_1),
                versioned_person.home_address.try(:address_2),
                versioned_person.home_address.try(:city),
                versioned_person.home_address.try(:state),
                versioned_person.home_address.try(:zip),
                mailing_address.try(:address_1),
                mailing_address.try(:address_2),
                mailing_address.try(:city),
                mailing_address.try(:state),
                mailing_address.try(:zip),
                citizen_status,
                naturalized_citizen,
                versioned_person.is_incarcerated,
                tribe_member
              ]
              count += 1
            rescue => e
              puts "Bad family member record with family id: #{fm.family.id}. Exception: #{e}"
            end
          end
        rescue => e
          puts "Bad Record. Exception: #{e}"
        end
      end
    end
    puts "Total person's that are created in a time frame of #{start_date}-#{end_date} count is #{count}"
  end
end
