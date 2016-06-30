require 'csv'

namespace :reports do
  namespace :shop do

    desc "Identify employer's updated account information"
    task :employer_profile_info_change => :environment do
      date_range = Date.today - 7.days..Date.today
      organizations = Organization.where(:'employer_profile'.exists=>true, :"employer_profile.aasm_state".in => ["applicant", "registered", "eligible", "binder_paid", "enrolled"])

      field_names  = %w(
          employer_legal_name
          fein
          address_kind
          address_1
          address_2
          address_3
          city
          state
          zip
          address_updated_at
          phone_kind
          area_code
          number
          phone_number_updated_at
          old_broker_agency_legal_name
          old_broker_npn
          old_broker_created_at
          old_broker_updated_at
          new_broker_agency_legal_name
          new_broker_npn
          new_broker_created_at
          old_poc_first_name
          old_poc_last_name
          old_poc_dob
          old_poc_created
          old_poc_updated
          new_poc_first_name
          new_poc_last_name
          new_poc_dob
          new_poc_created
        )
      processed_count = 0
      file_name = "#{Rails.root}/public/employer_profile_info_change.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        organizations.each do |organization|

          # find address updated in date range(Date.today - 7.days..Date.today) for a employer profile where address.kind => primary,mailing,branch

          address_change = organization.office_locations.
              where(:"address.kind".in => ["primary","mailing","branch"],:"address.updated_at" => date_range).flat_map(&:address).
              select{|address| address.updated_at.strftime('%Y-%m-%d') != address.office_location.organization.created_at.strftime('%Y-%m-%d')}

          # find phone_number updated in date range(Date.today - 7.days..Date.today) for a employer profile where address.kind => phone main

          phone_number_change = organization.office_locations.
              where(:"phone.kind".in => ["phone main"],:"phone.updated_at" => date_range).flat_map(&:phone).
              select{|phone| phone.updated_at.strftime('%Y-%m-%d') != organization.created_at.strftime('%Y-%m-%d')}

          # find old broker agency who assigned for a employer profile before broker agency changed in date range(Date.today - 7.days..Date.today)

          old_broker = organization.employer_profile.broker_agency_accounts.unscoped.
              where(:"updated_at" => date_range).select{|broker_agency| (broker_agency.updated_at.strftime('%Y-%m-%d') != broker_agency.employer_profile.created_at.strftime('%Y-%m-%d') && broker_agency.is_active == false)}.last.to_a

          # find updated active broker agency for a employer profile if exists in date range(Date.today - 7.days..Date.today)

          new_broker = organization.employer_profile.broker_agency_accounts.
              where(:"updated_at" => date_range).select{|broker_agency| broker_agency.updated_at.strftime('%Y-%m-%d') != broker_agency.employer_profile.created_at.strftime('%Y-%m-%d')}.first.to_a

          # find deleted poc's for a employer profile in date range(Date.today - 7.days..Date.today)

          old_poc = Person.where(:'employer_staff_roles.employer_profile_id' =>organization.employer_profile.id,
                                 :"employer_staff_roles.is_active" => true, :"employer_staff_roles.updated_at" => date_range). flat_map(&:employer_staff_roles).
              select{|employer_staff_role| employer_staff_role.aasm_state == "is_closed"}

          # find newly added poc's for a employer profile in date range(Date.today - 7.days..Date.today)

          new_poc = Person.where(:'employer_staff_roles.employer_profile_id' =>organization.employer_profile.id,
                                 :"employer_staff_roles.is_active" => true, :"employer_staff_roles.updated_at" => date_range). flat_map(&:employer_staff_roles).
              select{|employer_staff_role| employer_staff_role.aasm_state == "is_active" && employer_staff_role.created_at.strftime('%Y-%m-%d') != organization.employer_profile.created_at.strftime('%Y-%m-%d')}

          if (address_change.present? || phone_number_change.present? || old_broker.present? || new_broker.present? || old_poc.present? || new_poc.present? )

            max_size = [address_change.length, phone_number_change.length, old_broker.length, new_broker.length, old_poc.length, new_poc.length].max
            max_size.times do |index|

              if address_change[index].present?
                address_kind = address_change[index].try(:kind)
                address_1=address_change[index].try(:address_1)
                address_2 = address_change[index].try(:address_2)
                address_3 = address_change[index].try(:address_3)
                city = address_change[index].try(:city)
                state = address_change[index].try(:state)
                zip = address_change[index].try(:zip)
                address_updated_at = address_change[index].try(:updated_at)
              end

              if phone_number_change[index].present?
                phone_kind = phone_number_change[index].try(:kind)
                area_code = phone_number_change[index].try(:area_code)
                number = phone_number_change[index].try(:number)
                phone_number_updated_at = phone_number_change[index].try(:updated_at)
              end

              if old_broker[index].present?
                old_broker_agency_legal_name = old_broker[index].try(:broker_agency_profile).try(:legal_name)
                old_broker_npn = old_broker[index].try(:broker_agency_profile).try(:primary_broker_role).try(:npn)
                old_broker_created_at = old_broker[index].try(:created_at)
                old_broker_updated_at = old_broker[index].try(:updated_at)
              end

              if new_broker[index].present?
                new_broker_agency_legal_name = new_broker[index].try(:broker_agency_profile).try(:legal_name)
                new_broker_npn = new_broker[index].try(:broker_agency_profile).try(:primary_broker_role).try(:npn)
                new_broker_created_at = new_broker[index].try(:created_at)
              end

              if old_poc[index].present?
                old_poc_first_name = old_poc[index].try(:person).try(:first_name)
                old_poc_last_name = old_poc[index].try(:person).try(:last_name)
                old_poc_dob = old_poc[index].try(:person).try(:dob)
                old_poc_created = old_poc[index].try(:created_at)
                old_poc_updated = old_poc[index].try(:updated_at)
              end

              if new_poc[index].present?
                new_poc_first_name = new_poc[index].try(:person).try(:first_name)
                new_poc_last_name = new_poc[index].try(:person).try(:last_name)
                new_poc_dob = new_poc[index].try(:person).try(:dob)
                new_poc_created = new_poc[index].try(:created_at)
              end

              csv << [
                  organization.legal_name,
                  organization.fein,
                  address_kind,
                  address_1,
                  address_2,
                  address_3,
                  city,
                  state,
                  zip,
                  address_updated_at,
                  phone_kind,
                  area_code,
                  number,
                  phone_number_updated_at,
                  old_broker_agency_legal_name,
                  old_broker_npn,
                  old_broker_created_at,
                  old_broker_updated_at,
                  new_broker_agency_legal_name,
                  new_broker_npn,
                  new_broker_created_at,
                  old_poc_first_name,
                  old_poc_last_name,
                  old_poc_dob,
                  old_poc_created,
                  old_poc_updated,
                  new_poc_first_name,
                  new_poc_last_name,
                  new_poc_dob,
                  new_poc_created,

              ]
            end
            processed_count += 1
          end
        end
      end

      puts "For period #{date_range.first} - #{date_range.last}, #{processed_count} employer's updated account information to output file: #{file_name}"
    end
  end
end