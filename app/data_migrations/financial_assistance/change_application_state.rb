# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

# Change aasm_state of financial assistance application
class ChangeApplicationState < MongoidMigrationTask
  def migrate
    applications = find_applications
    action = ENV['action'].to_s

    case action
    when "cancel"
      cancel_application(applications)
    when "terminate"
      terminate_application(applications)
    end
  end

  def find_applications
    hbx_ids = ENV['hbx_id'].to_s.split(',').uniq
    hbx_ids.inject([]) do |enrollments, hbx_id|
      application = FinancialAssistance::Application.by_hbx_id(hbx_id.to_s)
      raise "Found no (OR) more than 1 enrollments with the #{hbx_id}" if application.size != 1 && !Rails.env.test?
      enrollments << application.first
    end
  end

  def terminate_application(applications)
    applications.each do |application|
      application.update_attributes!(aasm_state: "terminated")
      puts "application with hbx_id: #{application.hbx_id} terminated" unless Rails.env.test?
    end
  end

  def cancel_application(applications)
    applications.each do |application|
      application.update_attributes(aasm_state: "cancelled")
      puts "application with hbx_id: #{application.hbx_id} cancelled" unless Rails.env.test?
    end
  end
end
