families = Family.where({
  "households.hbx_enrollments" => {
    "$elemMatch" => {
      "kind" => "individual",
      "effective_on" => { "$gte" => Date.new(2017,1,1)},
  } }
})
batch_size = 500
offset = 0
family_count = families.count
electronic_communication = 0
paper_communication = 0

field_names  = %w(
          full_name
          hbx_id
          electronic_communication
          paper_communication
          aasm_state
         )

file_name = "report_of_communication_preferences_#{TimeKeeper.date_of_record.strftime('%m_%d')}.csv"
CSV.open(file_name, "w", force_quotes: true) do |csv|
  csv << field_names
  while offset <= family_count
    families.offset(offset).limit(batch_size).each do |family|
      begin
        enrollments = family.enrollments.where(:"effective_on" => {"$gte" => Date.new(2017,1,1)}, :"aasm_state".nin => ["coverage_canceled", "coverage_terminated"])
        if enrollments.present?
          person = family.primary_applicant.person
          if person.consumer_role.can_receive_electronic_communication?
            electronic_communication += 1
          end
          if person.consumer_role.can_receive_paper_communication?
            paper_communication += 1
          end
          csv << [person.full_name, person.hbx_id, person.consumer_role.can_receive_electronic_communication?, person.consumer_role.can_receive_paper_communication?, enrollments.map(&:aasm_state)]
        end
      rescue Exception => e
        puts "#{e.inspect}"
      end
    end
    offset = offset + batch_size
  end
end
puts "electronic_communication - #{electronic_communication} ***** paper_communication - #{paper_communication}"