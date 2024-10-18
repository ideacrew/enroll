# frozen_string_literal: true

# This script is used to sync the data between FAA applicants and people who has data mismatch starting
# 2024/5/6. This script will compare the attributes of the applicant and person and if there is any mismatch
# then it will update the person with the applicant attributes and update the family member id in the applicant.
# bundle exec rails runner script/fix_faa_applicants_people_data_sync.rb '2024' -e production

include Dry::Monads[:do, :result]
require 'csv'

assistance_year = if ARGV[0].present? && ARGV[0].to_i.to_s == ARGV[0]
                    ARGV[0].to_i
                  else
                    TimeKeeper.date_of_record.year
                  end

# Fetch all the family ids of the enrolled families in the current year
family_ids = ::HbxEnrollment.individual_market.enrolled.current_year.distinct(:family_id)

# Fetch all the applications of the enrolled families in the current year and who has applicants without tribe codes and ethnicity
applications = ::FinancialAssistance::Application.by_year(assistance_year).determined.where(
  :family_id.in => family_ids,
  :updated_at.gte => Date.new(2024,5,6).beginning_of_day,
  :applicants => {
    :$exists => true,
    :$elemMatch => {
      :$or => [
        { :tribe_codes => { :$exists => false } },
        { :tribe_codes => nil },
        { :ethnicity => { :$exists => false } },
        { :ethnicity => nil }
      ]
    }
  })

eligible_family_ids = applications.distinct(:family_id)

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

def applicant_info(keys, applicant)
  applicant_mismatch_hash = {}
  keys.each do |key|
    next if key == "ssn"

    applicant_mismatch_hash[key] = applicant.send(key.to_sym)
  end

  applicant_mismatch_hash
end

def person_info(keys, person)
  person_mismatch_hash = {}
  keys.each do |key|
    next if key == "ssn"

    person_mismatch_hash[key] = person.send(key.to_sym)
  end

  person_mismatch_hash
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

csv_file = "#{Rails.root}/faa_applicants_and_people_data_mismatch.csv"

CSV.open(csv_file, 'w', force_quotes: true) do |csv|
  csv << ['Application HBX ID', 'Person HBX ID', 'Applicant BSON ID', "Mismatch Info",  'Applicant Info', 'Person Info']

  puts 'Started running the FAA Applicants/Person sync'

  eligible_family_ids.each do |family_id|
    applications_by_family = ::FinancialAssistance::Application.where(family_id: family_id)
    application = applications_by_family.by_year(assistance_year).determined.created_asc.last

    application.applicants.each do |applicant|
      tribe_code = applicant.read_attribute(:tribe_codes)
      ethnicity = applicant.read_attribute(:ethnicity)

      if tribe_code.nil? || ethnicity.nil?
        person_hbx_id = applicant.person_hbx_id
        application_updated_at = application.updated_at

        person = Person.where(hbx_id: person_hbx_id).first
        person_updated_at = person.updated_at if person.present?

        next if person_updated_at.present? && person_updated_at > application_updated_at

        comparisions = compare_attributes(applicant, person)

        mismatch_info = comparisions.select { |k, v| v == false }.keys

        if mismatch_info.present?
          csv << [application.hbx_id, person_hbx_id, applicant.id.to_s, mismatch_info.join(", "), applicant_info(mismatch_info, applicant), person_info(mismatch_info, person)]

          trigger_update_to_main_app(applicant, application)
        end
      end
    rescue => e
      puts "Error occurred for application #{application.hbx_id} due to #{e.inspect}"
      Rails.logger.error "Error occurred for application #{application.hbx_id}: #{e.message} - #{e.backtrace&.join("\n")}"
    end
  end
  puts 'Completed running the FAA Applicants/Person sync'
end
