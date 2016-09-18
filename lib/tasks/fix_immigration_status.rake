require 'csv'
csv_file_path = "#{Rails.root}/non_native_NLP.csv"
namespace :consumer do
  desc "Fix Immigration Status"
  task fix_immigration_status: :environment do
    output_file_path = "#{Rails.root}/immigration_status_fix_result.csv"
    file = File.open(output_file_path, "w")
    CSV.foreach(csv_file_path, headers: true, :encoding => 'utf-8') do |row|
      person = Person.where(hbx_id: row.to_hash["policy.subscriber.person.hbx_id"]).first
      fix_citizen_status_overwritten_by_fedhub(person, file) if person.present?
    end
    file.close
  end
end

def fix_citizen_status_overwritten_by_fedhub(person, file)
  # 1. Iterate over all versions of the person instance in a descending order (latest first)
  # 2. Compare the citizen_status on the current person record to each Version of the person instance
        # 2a. When the two statuses differ, Copy the citizen_status of that specific version to the current person record.

  citizen_status = person.try(:consumer_role).try(:lawful_presence_determination).try(:citizen_status)
  file.puts "HBX ID : #{person.hbx_id}, Version Num. #{person.version} (updated_at: #{person.updated_at}), Citizen Status: #{citizen_status} (*current version*)"
  
  # Print Citizen Status for all Versions of Person record.
  person.versions.reverse.each { |pv| file.puts "HBX ID : #{pv.hbx_id}, Version Num. #{pv.version} (updated_at: #{pv.updated_at}), Citizen Status: #{pv.try(:consumer_role).try(:lawful_presence_determination).try(:citizen_status)}"}

  # 2a. When the two statuses differ, copy the citizen_status of that specific version to the current person record. 
  person.versions.reverse.each do |pv|
    citizen_status_for_this_version = pv.try(:consumer_role).try(:lawful_presence_determination).try(:citizen_status)
    if (citizen_status_for_this_version.present? && citizen_status == "non_native_not_lawfully_present_in_us" && citizen_status != citizen_status_for_this_version)
      person.consumer_role.lawful_presence_determination.update_attributes!(citizen_status: citizen_status_for_this_version)
      file.puts "Copied citizen_status from [Version #{pv.version}] to [Version: #{person.version} (current Person record)]"
      break
    end
  end
  file.puts "*" * 125
end