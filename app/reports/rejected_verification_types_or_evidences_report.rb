# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")
require 'csv'
require "#{Rails.root}/app/helpers/l10n_helper.rb"

# List of people with any verification_type or evidence in rejected status
class RejectedVerificationTypesOrEvidencesReport < MongoidMigrationTask
  include L10nHelper

  def people
    Person.rejected_verification_type
  end

  def assistance_year
    TimeKeeper.date_of_record.year
  end

  def applications
    FinancialAssistance::Application.by_year(assistance_year).submitted_and_after.or(
      :"applicants.income_evidence.aasm_state" => 'rejected'
    ).or(
      :"applicants.esi_evidence.aasm_state" => 'rejected'
    ).or(
      :"applicants.non_esi_evidence.aasm_state" => 'rejected'
    ).or(
      :"applicants.local_mec_evidence.aasm_state" => 'rejected'
    )
  end

  def families
    Family.or(
      :'family_members.person_id'.in => people.pluck(:id)
    ).or(
      :id.in => applications.distinct(:family_id)
    )
  end

  def show_v_type(status)
    if status == "curam"
      "External Source"
    elsif status
      status = "verified" if status == "valid"
      l10n('verification_type.validation_status') if status == 'rejected'
      status.capitalize
    end
  end

  def show_verification_status(status)
    status = "verified" if status == "valid"
    (status || '').capitalize
  end

  def display_evidence_type(evidence)
    { "ESI MEC" => "faa.evidence_type_esi",
      "Local MEC" => "faa.evidence_type_aces",
      "Non ESI MEC" => "faa.evidence_type_non_esi",
      "Income" => "faa.evidence_type_income" }[evidence]
  end

  def data_for_rejected_evidence(evidence, primary, application, active_enr, person)
    latest_wfst = evidence.workflow_state_transitions.order(created_at: :desc).first
    [primary.hbx_id,
     primary.last_name,
     primary.consumer_role&.contact_method,
     primary.work_email_or_best,
     application&.hbx_id,
     person.hbx_id,
     l10n(display_evidence_type(evidence.title)),
     show_verification_status(evidence.aasm_state.to_s),
     latest_wfst&.created_at&.in_time_zone('Eastern Time (US & Canada)'),
     active_enr.present? ? 'Yes' : 'No']
  end

  def data_for_rejected_v_type(v_type, primary, application, active_enr, person)
    latest_history = v_type.type_history_elements.order(created_at: :desc).first
    [primary.hbx_id,
     primary.last_name,
     primary.consumer_role&.contact_method,
     primary.work_email_or_best,
     application&.hbx_id,
     person.hbx_id,
     v_type.type_name,
     show_v_type(v_type.validation_status),
     latest_history&.created_at&.in_time_zone('Eastern Time (US & Canada)'),
     active_enr.present? ? 'Yes' : 'No']
  end

  def field_names
    %w[PrimaryHBXID LastName CommunicationPreference PrimaryEmailAddress
       ApplicationID MemberHBXID MemberVerificationType CurrentVerificationStatus
       LastStatusTransition ActiveEnrollment]
  end

  def process_family_members(family, csv, primary, application, active_enr)
    family.active_family_members.flat_map(&:person).each do |person|
      rejected_v_types = person.verification_types.where(validation_status: 'rejected').order(created_at: :desc)
      rejected_v_types.each do |v_type|
        csv << data_for_rejected_v_type(v_type, primary, application, active_enr, person)
      end
    end
    csv
  end

  def process_application(application, primary, csv, active_enr, family)
    application.applicants.each do |applicant|
      person = family.active_family_members.flat_map(&:person).detect { |per| per.hbx_id == applicant.person_hbx_id }
      next applicant unless person.present?
      [applicant.income_evidence, applicant.esi_evidence, applicant.non_esi_evidence, applicant.local_mec_evidence].each do |evidence|
        csv << data_for_rejected_evidence(evidence, primary, application, active_enr, person) if evidence&.aasm_state == 'rejected'
      end
    end
  end

  def process_families(offset_count, csv)
    families.no_timeout.limit(10_000).offset(offset_count).inject([]) do |_dummy, family|
      primary = family.primary_person
      application = FinancialAssistance::Application.by_year(assistance_year).submitted_and_after.where(family_id: family.id).order(created_at: :desc).first
      active_enr = family.hbx_enrollments.by_year(assistance_year).enrolled_and_renewal.order(created_at: :desc).first
      csv = process_family_members(family, csv, primary, application, active_enr)
      process_application(application, primary, csv, active_enr, family) if application.present?
    rescue StandardError => e
      puts "Unable to process person with hbx_id: #{primary&.hbx_id}, message: #{e.message}, backtrace: #{e.backtrace}" unless Rails.env.test?
    end
  end

  def migrate
    file_name = "#{Rails.root}/rejected_verification_types_or_evidences_report.csv"
    CSV.open(file_name, 'w', force_quotes: true) do |csv|
      csv << field_names
      total_count = families.count
      puts "Total number of families: #{total_count}" unless Rails.env.test?
      familes_per_iteration = 10_000.0
      number_of_iterations = (total_count / familes_per_iteration).ceil
      counter = 0

      while counter < number_of_iterations
        puts "Processing #{counter.next.ordinalize} 10000 families." unless Rails.env.test?
        offset_count = familes_per_iteration * counter
        process_families(offset_count, csv)
        counter += 1
      end
    end
    puts "*********** DONE ******************" unless Rails.env.test?
  end
end
