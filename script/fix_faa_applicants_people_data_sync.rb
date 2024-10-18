# frozen_string_literal: true

# This script is used to sync the data between FAA applicants and people who has data mismatch starting
# 2024/5/6. This script will compare the attributes of the applicant and person and if there is any mismatch
# then it will update the person with the applicant attributes and update the family member id in the applicant.
# bundle exec rails runner script/fix_faa_applicants_people_data_sync.rb 'faa_applicants_and_people_data_mismatch.csv' -e production

include Dry::Monads[:do, :result]
require 'csv'

file_name = if ARGV[0].present?
              ARGV[0].to_s
            end

def address_comparision(applicant_addresses, person_addresses)
  return false if applicant_addresses.blank? || person_addresses.blank?

  applicant_home_address = applicant_addresses.detect { |addr| addr.kind == "home" }
  person_home_address = person_addresses.detect { |addr| addr.kind == "home" }

  if person_home_address.present? && applicant_home_address.present?
    if person_home_address.updated_at < applicant_home_address.updated_at && person_home_address.attributes.slice(:kind, :address_1, :address_2, :address_3, :city, :county, :state, :zip) != applicant_home_address.attributes.slice(:kind, :address_1, :address_2, :address_3, :city, :county, :state, :zip)
      return false
    end
  end


  applicant_mailing_address = applicant_addresses.detect { |addr| addr.kind == "mailing" }
  person_mailing_address = person_addresses.detect { |addr| addr.kind == "mailing" }

  if applicant_mailing_address.present? && person_mailing_address.present?
    if person_mailing_address.updated_at < applicant_mailing_address.updated_at && person_mailing_address.attributes.slice(:kind, :address_1, :address_2, :address_3, :city, :county, :state, :zip) != applicant_mailing_address.attributes.slice(:kind, :address_1, :address_2, :address_3, :city, :county, :state, :zip)
      return false
    end
  end

  true
end

def trigger_update_to_main_app(applicant, application)
  create_or_update_member_params = { applicant_params: applicant.attributes_for_export, family_id: application.family_id }
  create_or_update_result = if FinancialAssistanceRegistry[:avoid_dup_hub_calls_on_applicant_create_or_update].enabled?
                              create_or_update_member_params[:applicant_params].merge!(is_primary_applicant: applicant.is_primary_applicant?, skip_consumer_role_callbacks: true, skip_person_updated_event_callback: true)
                              ::Operations::Families::CreateOrUpdateMember.new.call(create_or_update_member_params)
                            end

  if create_or_update_result.success?
    response_family_member_id = create_or_update_result.success[:family_member_id]
    applicant.update_attributes!(family_member_id: response_family_member_id) if applicant.family_member_id.nil?
  end
end

def compare_attributes(applicant, person)
  {
    first_name: applicant.first_name.downcase == person.first_name.downcase,
    last_name: applicant.last_name.downcase == person.last_name.downcase,
    is_applying_coverage: applicant.is_applying_coverage == person.is_applying_coverage,
    is_incarcerated: applicant.is_incarcerated == person.is_incarcerated,
    us_citizen: applicant.us_citizen == person.us_citizen,
    citizen_status: applicant.citizen_status == person.consumer_role.lawful_presence_determination.citizen_status,
    indian_tribe_member: applicant.indian_tribe_member == person.indian_tribe_member,
    ssn: applicant.ssn == person.ssn,
    dob: applicant.dob == person.dob,
    naturalized_citizen: applicant.naturalized_citizen == person.naturalized_citizen,
    addresses: address_comparision(applicant.addresses, person.addresses)
  }
end

file_path = "#{Rails.root}/#{file_name}"

CSV.foreach(file_path, headers: true) do |row|
  application = ::FinancialAssistance::Application.where(hbx_id: row['Application HBX ID']).first
  applicant = application.applicants.where(person_hbx_id: row['Person HBX ID']).first

  person_hbx_id = applicant.person_hbx_id
  application_updated_at = application.updated_at

  person = Person.where(hbx_id: person_hbx_id).first
  person_updated_at = person.updated_at if person.present?

  next if person_updated_at.present? && person_updated_at > application_updated_at

  comparisions = compare_attributes(applicant, person)

  mismatch_info = comparisions.select { |k, v| v == false }.keys

  if mismatch_info.present?
    trigger_update_to_main_app(applicant, application)
  end
rescue => e
  puts "Error occurred for application #{row['Application HBX ID']} due to #{e.inspect}"
  Rails.logger.error "Error occurred for application #{row['Application HBX ID']}: #{e.message} - #{e.backtrace&.join("\n")}"
end
