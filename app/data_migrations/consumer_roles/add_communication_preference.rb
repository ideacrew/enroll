# frozen_string_literal: true

require File.join(Rails.root, 'lib/mongoid_migration_task')

# Adds missing communication preference for all primary people with consumer role & without communication preference
class AddCommunicationPreference < MongoidMigrationTask
  def migrate
    add_missing_communication_preference
  end

  private

  def add_missing_communication_preference
    CSV.open(csv_file_name, 'w', force_quotes: true) do |csv|
      csv << csv_headers
      logger.info "Total number of families to process: #{eligible_families.count}"

      eligible_families.each do |family|
        logger.info "Processing family #{family.id}"
        primary = family.primary_person
        current_application = latest_determined_application(family, system_year).first
        renewal_application = latest_determined_application(family, system_year.next).first

        next family if primary.consumer_role.blank?
        csv << [
          primary.hbx_id,
          primary.full_name,
          primary.consumer_role.contact_method,
          update_person_contact_method(primary.consumer_role),
          current_application&.hbx_id,
          current_application&.primary_applicant&.person_hbx_id,
          renewal_application&.hbx_id,
          renewal_application&.primary_applicant&.person_hbx_id
        ]
      rescue StandardError => e
        logger.error "Error while processing family #{family.id}: #{e.message}"
      end
    end
  end

  def contact_method_mail_only
    @contact_method_mail_only ||= ::ConsumerRole::CONTACT_METHOD_MAPPING[['Mail']]
  end

  def csv_file_name
    "#{Rails.root}/primary_people_with_updated_contact_method.csv"
  end

  def csv_headers
    [
      'Primary Person HBX ID',
      'Primary Person Name',
      'Current Person Contact Method',
      'Updated Person Contact Method',
      'Current Year Latest Determined App HBX ID',
      'Current Year Latest Determined App Primary Applicant HBX ID',
      'Renewal Year Latest Determined App HBX ID',
      'Renewal Year Latest Determined App Primary Applicant HBX ID'
    ]
  end

  def eligible_families
    @eligible_families ||= Family.where(:'family_members.person_id'.in => people_without_contact_method.pluck(:id))
  end

  def latest_determined_application(family, assistance_year)
    FinancialAssistance::Application.all.where(
      aasm_state: 'determined',
      assistance_year: assistance_year,
      family_id: family.id
    ).order(submitted_at: :desc)
  end

  def logger
    @logger ||= ::Logger.new(logger_file_name)
  end

  def logger_file_name
    "#{Rails.root}/log/add_missing_communication_preference.log"
  end

  def people_without_contact_method
    Person.all.where(
      :consumer_role.exists => true,
      :'consumer_role.contact_method' => nil
    )
  end

  def system_year
    @system_year ||= TimeKeeper.date_of_record.year
  end

  def update_person_contact_method(consumer_role)
    consumer_role.contact_method = contact_method_mail_only
    consumer_role.save!
    consumer_role.contact_method
  end
end
