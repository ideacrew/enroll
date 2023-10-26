# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")
# Task to remove specified hbx_enrollments and people records
class RemoveOldIfsvCases < MongoidMigrationTask
  def migrate
    hbx_ids = ENV['hbx_ids'].split(',')
    ssns    = ENV['ssns'].split(',')

    destroyed_hbx_enrollment_ids = []
    destroyed_ssns = []

    destroy_hbx_enrollments(hbx_ids, destroyed_hbx_enrollment_ids)

    destroy_people(ssns, destroyed_ssns)

    if destroyed_hbx_enrollment_ids.count == hbx_ids.count
      puts "All specified (#{hbx_ids.count}) hbx_enrollments were destroyed"
    else
      puts "The following hbx_enrollments were not destroyed: #{hbx_ids - destroyed_hbx_enrollment_ids}"
    end

    if destroyed_ssns.count == ssns.count
      puts "All specified (#{destroyed_ssns.count}) people were destroyed"
    else
      puts "The following SSNs people were not destroyed: #{ssns - destroyed_ssns}"
    end
  end

  def destroy_hbx_enrollments(hbx_ids, destroyed_hbx_enrollment_ids)
    hbx_enrollments = HbxEnrollment.where(hbx_id: hbx_ids)
    hbx_enrollments.each do |hbx_enrollment|
      destroyed_hbx_enrollment_ids.push(hbx_enrollment.hbx_id) if hbx_enrollment.destroy
    end
  end

  def destroy_people(ssns, destroyed_ssns)
    ssns.each do |ssn|
      person = Person.find_by_ssn(ssn)
      destroyed_ssns.push(ssn) if person&.destroy
    end
  end
end
