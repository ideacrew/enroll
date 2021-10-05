# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')


# Update bulk broker email from CSV
# Just need to confirm the formats
# rubocop:disable Metrics/CyclomaticComplexity:
class UpdateBulkBrokerEmails < MongoidMigrationTask
  def migrate
    filename = "#{Rails.root}/update_bulk_broker_emails_*.csv"
    update_broker_csvs = Dir.glob(filename)
    puts("No broker CSV present. Please place CSV in Enroll root directory with filename update_bulk_broker_emails_*.") if update_broker_csvs.blank?
    abort if update_broker_csvs.blank?
    broker_csv_file = update_broker_csvs.first
    broker_csv = File.read(broker_csv_file)
    CSV.parse(broker_csv, :headers => true).each do |broker_info|
      npn = broker_info[0]
      current_email = broker_info[3]
      desired_email = broker_info[4]
      broker_role = BrokerRole.by_npn(npn).first
      puts("No broker role present for #{npn}") if broker_role.blank?
      next if broker_role.blank?
      email = broker_role&.person&.emails&.where(address: current_email)&.first
      puts("No email present") if email.blank?
      puts("Updating email for broker with npn #{npn}") if email.present?
      next if email.blank?
      result = email.update_attributes(address: desired_email)
      puts("Email updated for broker with npn #{npn}") if result
    end
  end
end
# rubocop:enable Metrics/CyclomaticComplexity:
