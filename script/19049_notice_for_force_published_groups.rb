event_kind = ApplicationEventKind.where(:event_name => "planyear_renewal_3b").first
notice_trigger = event_kind.notice_triggers.first
csv_file_path = "19049_force_published_list.csv"

CSV.foreach(csv_file_path, headers: true, :encoding => 'utf-8') do |row|
  org = Organization.where(:fein => row["fein"]).first
  emp = org.employer_profile
  begin
    plan_year = emp.plan_years.where(:aasm_state => "renewing_enrolled")
    if plan_year.present?
      builder = notice_trigger.notice_builder.camelize.constantize.new(emp, {
                template: notice_trigger.notice_template,
                subject: event_kind.title,
                event_name: "planyear_renewal_3b",
                mpi_indicator: notice_trigger.mpi_indicator,
                }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver
      puts "Delivered notice to #{emp.legal_name}"
    else
      puts "Didn't send notice because of #{emp.legal_name}'s plan year aasm state - #{emp.plan_years.last.aasm_state}"
    end
  rescue Exception => e
    puts "Unable to deliver notice for #{emp.legal_name} -- #{emp.fein}"
    puts "#{e.inspect}"
  end
end