organizations = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {:start_on.gte => Date.new(2017,6,1)}})

organizations.each do |org|  
  begin
  if (org.employer_profile.inbox.messages.where(:subject => "Group Renewal Available").first.present? || org.employer_profile.documents.where(:title => "GroupRenewalAvailable").first.present?)
    event = "group_renewal_5"
    event_kind = ApplicationEventKind.where(:event_name => event).first
    notice_trigger = event_kind.notice_triggers.first
    builder = notice_trigger.notice_builder.camelize.constantize.new(org.employer_profile, {
              template: notice_trigger.notice_template,
              subject: event_kind.title,
              key: "corrected",
              mpi_indicator: notice_trigger.mpi_indicator,
              }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)).deliver
    puts "Delivered notice to #{org.legal_name}" unless Rails.env.test?
  else
    puts "No notice present for #{org.legal_name}" unless Rails.env.test?
  end
  rescue Exception => e
    puts "Unable to send group_renewal_5 notice to #{org.legal_name} due to #{e}" unless Rails.env.test?
  end
end
