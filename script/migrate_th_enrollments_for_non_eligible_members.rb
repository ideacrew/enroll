# frozen_string_literal: true

def build_taxhousehold_enrollments(hbx_enrollment, tax_household_group)
  tax_household_group.tax_households.where(:'tax_household_members.applicant_id'.in => hbx_enrollment.hbx_enrollment_members.map(&:applicant_id)).each do |tax_household|
    th_enrollment = TaxHouseholdEnrollment.find_or_create_by(enrollment_id: hbx_enrollment.id, tax_household_id: tax_household.id)
    hbx_enrollment_members = hbx_enrollment.hbx_enrollment_members
    tax_household_members = tax_household.tax_household_members

    (tax_household_members.map(&:applicant_id).map(&:to_s) & enrolled_family_member_ids(hbx_enrollment)).each do |family_member_id|
      hbx_enrollment_member = hbx_enrollment_members.where(applicant_id: family_member_id).first
      tax_household_member_id = tax_household_members.where(applicant_id: family_member_id).first&.id

      th_member_enr_member = th_enrollment.tax_household_members_enrollment_members.find_or_create_by(
        family_member_id: family_member_id
      )

      th_member_enr_member.update!(
        hbx_enrollment_member_id: hbx_enrollment_member&.id,
        tax_household_member_id: tax_household_member_id,
        age_on_effective_date: hbx_enrollment_member&.age_on_effective_date,
        relationship_with_primary: hbx_enrollment_member&.primary_relationship,
        date_of_birth: hbx_enrollment_member&.person&.dob
      )
    end
  end
end

def enrolled_family_member_ids(hbx_enrollment)
  hbx_enrollment.hbx_enrollment_members.map(&:applicant_id).map(&:to_s)
end

def find_tax_household_group(family, enrollment)
  tax_household_groups = family.tax_household_groups.by_year(enrollment.effective_on.year).order_by(:created_at.desc)
  return nil if tax_household_groups.blank?

  # happy path, 2023
  target_th_group = tax_household_groups.where(:created_at.lte => enrollment.created_at).first
  return target_th_group if target_th_group.present?

  # Found none - we need to get right tax household group through legacy tax households.

  legacy_tax_households = family.active_household.tax_households.tax_household_with_year(enrollment.effective_on.year).order_by(:created_at.desc)
  eligible_legacy_thhs = legacy_tax_households.where(:created_at.lte => enrollment.created_at)
  legacy_th = eligible_legacy_thhs.where(:'eligibility_determinations.source'.ne => 'Admin').first || eligible_legacy_thhs.first
  return nil if legacy_th.blank?

  mapped_th_group = tax_household_groups.where(:'tax_households.legacy_hbx_assigned_id' => legacy_th.hbx_assigned_id).first

  return mapped_th_group if mapped_th_group.present?

  # here comes the guess game. expectation is we always return something by now.

  if tax_household_groups.size == 1
    @logger.info "Guess: only one tax household group for given effective_on date. picking it for #{enrollment.hbx_id}"
    return tax_household_groups.first
  end

  @logger.info "Weird: Multiple tax_household_groups given effective_on date. No mapped tax household group(legacy) #{enrollment.hbx_id}"
end

def migrate_tax_household_enrollments(family)
  primary_hbx_id = family.primary_applicant&.person&.hbx_id
  enrollments = family.active_household.hbx_enrollments.by_health.enrolled_waived_terminated_and_expired.where(:effective_on => {:"$gte" => Date.new(2022, 1, 1), :"$lte" => Date.today.end_of_year})

  enrollments.each do |enrollment|
    tax_household_enrollments = TaxHouseholdEnrollment.where(enrollment_id: enrollment.id)
    tax_household_groups = family.tax_household_groups.by_year(enrollment.effective_on.year).where(:'tax_households._id'.in => tax_household_enrollments.map(&:tax_household_id).uniq)

    if tax_household_groups.size == 1
      enrolled_members = enrollment.hbx_enrollment_members.map(&:id).sort
      member_ids = tax_household_enrollments.flat_map(&:tax_household_members_enrollment_members).map(&:hbx_enrollment_member_id).sort.uniq
      next if enrolled_members == member_ids

      tax_household_group = tax_household_groups.first
    else
      tax_household_group = find_tax_household_group(family, enrollment)
      next if tax_household_group.blank?
    end

    build_taxhousehold_enrollments(enrollment, tax_household_group)

    th_enrollments = TaxHouseholdEnrollment.where(enrollment_id: enrollment.id)

    @logger.info "**** Processed EnrollmentHbxId - #{enrollment.hbx_id}; #{enrollment.effective_on}; #{enrollment.aasm_state}; Primary Hbx Id - #{primary_hbx_id}; Tax Households Count - #{th_enrollments.size}; APTC - #{th_enrollments.map(&:available_max_aptc)} ****"
    nil
  end
end

def process_families
  counter = 0

  Family.where(:tax_household_groups => {:"$exists" => true}).no_timeout.each do |family|
    counter += 1
    @logger.info "Processed #{counter} families count so far by #{DateTime.current}. Took #{((DateTime.current - @start_time) * 24 * 60).to_f.ceil}" if counter % 500 == 0

    unless family.valid?
      @logger.info "----- Invalid family with family_hbx_assigned_id: #{family.hbx_assigned_id}, errors: #{family.errors.full_messages}"
      next
    end

    migrate_tax_household_enrollments(family)
  rescue StandardError => e
    @rescue_hbx_ids << family.hbx_assigned_id
    @logger.info "----- Error raised processing family with family_hbx_assigned_id: #{family.hbx_assigned_id}, error: #{e}, backtrace: #{e.backtrace.join('\n')}"
  end
end


@logger = Logger.new("#{Rails.root}/log/migrate_th_enrollments_for_non_eligible_members_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
@start_time = DateTime.current
@logger.info "started migrations: #{@start_time}"
@rescue_hbx_ids = []
process_families
end_time = DateTime.current
@logger.info "MigrateHouseholdThhsToThhGroupThhs end_time: #{end_time}, total_time_taken_in_minutes: #{((end_time - @start_time) * 24 * 60).to_f.ceil}" unless Rails.env.test?
@logger.info "Families rescued - #{@rescue_hbx_ids}"

