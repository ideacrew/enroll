all_families = Family.by_enrollment_individual_market.where(:'households.hbx_enrollments.aasm_state' => "enrolled_contingent")

all_families.each do |family|
  begin
    family.update_attributes!(min_verification_due_date: family.min_verification_due_date_on_family)
  rescue Exception => e
    puts "Resolve errors with family of id: #{family.id}"
    puts "#{e}"
  end
end

