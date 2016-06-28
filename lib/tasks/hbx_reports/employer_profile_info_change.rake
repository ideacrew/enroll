require 'csv'

namespace :reports do
  namespace :shop do

    desc "Identify employer's updated account information"
    task :employer_profile_info_change => :environment do
      # date= picks every week start date..end dates i.e mon..sun
      date_range = Date.today.beginning_of_week..Date.today.at_end_of_week

      organizations = Organization.where(:'employer_profile'.exists=>true, :"employer_profile.aasm_state".in => ["applicant", "registered", "eligible", "binder_paid", "enrolled"])

      field_names  = %w(
          employer_legal_name
          fein
          address_change
          phone_number_change
          broker_change
          poc_change
        )
      processed_count = 0
      file_name = "#{Rails.root}/public/employer_profile_info_change.csv"

      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        organizations.each do |organization|
          # employer updated address during the current week
          address_change = true if organization.office_locations.where(:"address.kind".in => ["primary","mailing","branch"],:"address.updated_at" => date_range).flat_map(&:address).select{|addres| addres.updated_at != addres.office_location.organization.created_at}.present?
          # employer updated phone number during the current week
          phone_number_change = true if organization.office_locations.where(:"phone.kind".in => ["phone main"],:"phone.updated_at" => date_range).flat_map(&:phone).select{|phon| phon.updated_at != phon.office_location.organization.created_at}.present?
          # employer changed the broker during the current week
          broker_change = true if organization.employer_profile.broker_agency_accounts.unscoped.where(:"updated_at" => date_range).select{|a| a.updated_at != a.created_at}.present?
          # employer changed point of contact during the current week
          poc_change = true if Person.where(:'employer_staff_roles.employer_profile_id' =>organization.employer_profile.id, :"employer_staff_roles.is_active" => true, :"employer_staff_roles.updated_at" => date_range).flat_map(&:employer_staff_roles).select{|employer_staff_role| employer_staff_role.updated_at != employer_staff_role.created_at}.present?
          if (address_change || phone_number_change|| broker_change || poc_change )

              csv << [
                organization.legal_name,
                organization.fein,
                address_change,
                phone_number_change,
                broker_change,
                poc_change
            ]

            processed_count += 1
          end
        end
      end

      puts "For period #{date_range.first} - #{date_range.last}, #{processed_count} employer's updated account information to output file: #{file_name}"
    end
  end
end