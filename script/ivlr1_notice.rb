  begin
    csv = CSV.open('testing1.csv',"r",:headers =>true )
    @data= csv.to_a
    # binding.pry
  rescue Exception => e
    puts "Unable to open file #{e}"
  end
  event_kind = ApplicationEventKind.where(:event_name => 'ivl_renewal_notice_1').first
  notice_trigger = event_kind.notice_triggers.first

  @data.each do |row| 
    person = Person.where(:hbx_id => row["hbx_id"]).first
    # binding.pry
    consumer_role =person.consumer_role
    if  consumer_role.present?
      builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
            template: notice_trigger.notice_template, 
            subject: event_kind.title, 
            mpi_indicator: notice_trigger.mpi_indicator,
            data: row
            }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)
            )
      builder.deliver
    else
      puts "Unable to send notice to "
    end
  end
