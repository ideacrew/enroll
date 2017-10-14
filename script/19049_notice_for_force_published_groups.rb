event_kind = ApplicationEventKind.where(:event_name => "planyear_renewal_3b").first
notice_trigger = event_kind.notice_triggers.first
csv_file_path = "#{Rails.root}/19049_force_published_list.csv}"

CSV.foreach(csv_file_path, headers: true, :encoding => 'utf-8') do |row|
  org = Organization.where(:fein => row["fein"])
  emp = org.employer_profile
  begin
    builder = notice_trigger.notice_builder.camelize.constantize.new(emp, {
              template: notice_trigger.notice_template,
              subject: event_kind.title,
              mpi_indicator: notice_trigger.mpi_indicator,
              }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver
    puts "Delivered notice to #{emp.legal_name}"
  rescue Exception => e
    puts "Unable to deliver notice for #{emp.legal_name} -- #{emp.fein}"
    puts "#{e.inspect}"
  end
end