# frozen_string_literal: true

# This script generates a CSV report which lists the results of a DMF call
# each user who recieved a dmf determination will be listed
# along with other information (enrollment status, previous and current state of alive status verification, etc.)

# to run this script, first find the Transmittable::Job job_id of the dmf call that was run
# then enter the following:
# bundle exec rails runner script/generate_post_dmf_call_report.rb [*job_id*]

require "#{Rails.root}/app/domain/operations/families/verifications/dmf_determination/dmf_utils.rb"
include ::Operations::Families::Verifications::DmfDetermination::DmfUtils # rubocop:disable Style/MixinUsage

if EnrollRegistry.feature_enabled?(:alive_status)
  csv_headers = [
    "Family Hbx ID",
    "Person Hbx ID",
    "Enrollment Status",
    "Before DMF call deceased verification state",
    "After DMF call deceased verification state"
  ].freeze

  # ARGV[0] is the arg provided when calling the script --> it should be a valid job_id
  job = ::Transmittable::Job.where(job_id: ARGV[0]).last

  p "Job not found, report not run" and return unless job

  dmf_call_consumers = []

  family_hbx_ids = job.transmissions.where(key: :dmf_determination_response).no_timeout.each_with_object([]) do |transmission, array|
    array << transmission.transmission_id if transmission.process_status.latest_state == :succeeded
    array
  end

  p "No families found for #{job.job_id}" and return unless family_hbx_ids.present?

  family_hbx_ids.each do |family_hbx_id|
    family = Family.where(:hbx_assigned_id => family_hbx_id).first
    next unless family

    family.family_members.each do |member|
      next unless member_dmf_determination_eligible_enrollments(member, family)
      next unless AcaEntities::Operations::EncryptedSsnValidator.new.call(member.person.encrypted_ssn).success?

      _enrollment_hbx_id, enrollment_status = extract_enrollment_info(family, member.hbx_id)
      before_dmf_state, after_dmf_state = extract_dmf_states(member)

      consumer_hash = {
        family_hbx_id: family.hbx_assigned_id,
        person_hbx_id: member.person.hbx_id,
        enrollment_status: enrollment_status,
        before_dmf_state: before_dmf_state,
        after_dmf_state: after_dmf_state
      }

      dmf_call_consumers << consumer_hash
    end
  rescue StandardError => e
    p "Error processing family with hbx_id #{family.hbx_assigned_id} due to #{e}"
  end

  p "found #{dmf_call_consumers.size} consumers included in dmf call with job_id #{job.job_id}"  unless Rails.env.test?

  file_name = "post_dmf_call_report_for_job_#{job.job_id}.csv"
  CSV.open(file_name, "w") do |csv|
    csv << csv_headers
    consumers_counter = 0

    puts "Processing post-dmf call consumers" unless Rails.env.test?

    dmf_call_consumers.each do |consumer_hash|
      consumers_counter += 1
      puts "Processing person with hbx_id #{person.hbx_id} and index at #{consumers_counter}" unless Rails.env.test?

      csv << [
        consumer_hash[:family_hbx_id],
        consumer_hash[:person_hbx_id],
        consumer_hash[:enrollment_status],
        consumer_hash[:before_dmf_state],
        consumer_hash[:after_dmf_state]
      ]
    end
    p "processed #{consumers_counter} consumers after in dmf call with job_id #{job.job_id}"  unless Rails.env.test?
  end
else
  p "alive_status feature is not active for this environment"
end
