#Example: rails runner script/ivl_tax_cover_letter_notice.rb -e production

person = Person.all_consumer_roles.first
consumer_role = person.consumer_role if person.present?

if person.present? && consumer_role.present?
  begin
    event_kind = ApplicationEventKind.where(:event_name => 'ivl_tax_cover_letter_notice').first
    notice_trigger = event_kind.notice_triggers.first
    ["true", "false"].each do |t_or_f|
      builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
      template: notice_trigger.notice_template,
      subject: event_kind.title,
      event_name: 'ivl_tax_cover_letter_notice',
      options: { :is_an_aqhp_hbx_enrollment=> t_or_f},
      mpi_indicator: notice_trigger.mpi_indicator
      }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)
      )
      builder.deliver

      if t_or_f == "true"
        puts "1095a notice generated with AQHP cover letter for person with hbx_id: #{person.hbx_id}" unless Rails.env.test?
      else
        puts "1095a notice generated with UQHP cover letter for person with hbx_id: #{person.hbx_id}" unless Rails.env.test?
      end
    end
  rescue => e
    puts "Unable to deliver to #{person.hbx_id} for the following error #{e.backtrace}" unless Rails.env.test?
  end
end