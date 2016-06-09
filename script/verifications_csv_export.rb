people_to_check = Person.where("consumer_role.lawful_presence_determination.aasm_state" => "verification_outstanding")
puts "Candidate People: #{people_to_check.count}"

families = Family.where("family_members.person_id" => {"$in" => people_to_check.map(&:_id)})
puts "Candidate Families: #{families.count}"

mailing_address_missing = []
coverage_not_found = []
pending_ssa_validation = []
docs_uploaded = []

CSV.open("verification_backlog_report_rev8.csv", "w") do |csv|

  csv << [
    'Primary HbxId',
    'Primary Firstname', 
    'Primary Lastname',
    'Address',
    'Verification Due Date', 
    'Enrollment Submitted On', 
    'Coverage Start Date', 
    'SSN Unverified', 
    'Citizenship/Immigration Unverified',
    'Communication Preference',
    'EMail'
  ]

  count   = 0
  counter = 0

  families.each do |family|
    counter += 1

    next if family.id.to_s == "564d098469702d174fa10000"
    person = family.primary_applicant.person

    if person.consumer_role.blank?
      count += 1
      next
    end

    begin
      event_kind = ApplicationEventKind.where(:event_name => 'verifications_backlog').first
      notice_trigger = event_kind.notice_triggers.first 

      builder = notice_trigger.notice_builder.camelize.constantize.new(person.consumer_role, {
        template: notice_trigger.notice_template, 
        subject: event_kind.title, 
        mpi_indicator: notice_trigger.mpi_indicator
        }.merge(notice_trigger.notice_trigger_element_group.notice_peferences))

      builder.build
      csv << builder.to_csv 

    rescue Exception  => e
      case e.to_s 
      when 'needs ssa validation!'
        pending_ssa_validation << person.full_name
      when 'mailing address not present'
        mailing_address_missing << person.full_name
      when 'active coverage not found!'
        coverage_not_found << person.full_name
      when 'documents already uploaded'
        docs_uploaded << person.full_name
      end
    end

    if counter % 200 == 0
      puts "processed #{counter} families"
    end
  end

  puts "#{count} families skipped due to missing consumer role"

  puts pending_ssa_validation.count 
  puts mailing_address_missing.count
  puts coverage_not_found.count
  puts docs_uploaded.inspect
  puts docs_uploaded.count
end