def update_tax_household_enrollment_members(hbx_enrollment, tax_enrollment)
  updates = []
  tax_enrollment.tax_household_members_enrollment_members.each do |tax_enrollment_member|
    hbx_enrollment_member = hbx_enrollment.hbx_enrollment_members.detect{|hem| hem.applicant_id == tax_enrollment_member.family_member_id}
    if tax_enrollment_member.hbx_enrollment_member_id.to_s != hbx_enrollment_member.id.to_s
      tax_enrollment_member.hbx_enrollment_member_id = hbx_enrollment_member.id
      updates << "updated hbx_enrollment_member_id for family_member_id #{tax_enrollment_member.family_member_id}"
    end
  end
  tax_enrollment.save
  updates
end

def is_continous_coverage_enrollment?(enrollment)
  enrollment.hbx_enrollment_members.any?{|en_member| en_member.coverage_start_on < enrollment.effective_on}
end

def process_enrollment(enrollment)
  tax_enrollment = TaxHouseholdEnrollment.where(:enrollment_id => enrollment.id).first
  return unless tax_enrollment
  en_members_mismatched = (tax_enrollment.tax_household_members_enrollment_members.pluck(:hbx_enrollment_member_id) - enrollment.hbx_enrollment_members.pluck(:id)).present?
  return unless en_members_mismatched
  updates = update_tax_household_enrollment_members(enrollment, tax_enrollment)
  family = enrollment.family
  [
    family.primary_person.hbx_id,
    family.hbx_assigned_id,
    enrollment.hbx_id,
    enrollment.effective_on.strftime("%m/%d/%Y"),
    enrollment.created_at.strftime("%m/%d/%Y"),
    enrollment.coverage_kind,
    enrollment.aasm_state.titleize,
    tax_enrollment.created_at.strftime("%m/%d/%Y"),
    en_members_mismatched,
    is_continous_coverage_enrollment?(enrollment),
    updates.join("\n")
  ]
end

enrollments = HbxEnrollment.where(:aasm_state.nin => ["shopping"]).where(:effective_on.gte => Date.new(2022,1,1))
batch_size = 1000
query_offset = 0

p "total enrollments #{enrollments.count}"

CSV.open("tax_enrollment_members_issues_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv", "w") do |csv|

  csv << [
      "primary hbx id",
      "family hbx id",
      "enrollment hbx id",
      "enrollment effective date",
      "enrollment created on", 
      "enrollment coverage kind",
      "enrollment status",
      "tax_household_enrollment created on",
      "enrollment_members mismatched",
      "is continous coverage",
      "updates"
  ]

  while enrollments.count > query_offset
    batched_enrollments = enrollments.skip(query_offset).limit(batch_size)
    enrollment_row = []
    counter = 0
    batched_enrollments.no_timeout.each do |enrollment|
      counter += 1
      if counter % 100 == 0 
          p  "processed #{counter} batch enrollments"
      end

      enrollment_row = process_enrollment(enrollment)
      csv << enrollment_row if enrollment_row
    end

    puts enrollment_row.inspect
    query_offset += batch_size
    p "Processed #{query_offset} enrollments."
  end
end


