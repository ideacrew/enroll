puts "-------------------------------------- Start of rake: #{TimeKeeper.datetime_of_record} --------------------------------------" unless Rails.env.test?
begin
  @data_hash = {}
  CSV.foreach('uqhp_projected_eligibility_notice_report.csv',:headers =>true).each do |d|
    if @data_hash[d["family.id"]].present?
      hbx_ids = @data_hash[d["family.id"]].collect{|r| r['policy.subscriber.person.hbx_id']}
      next if hbx_ids.include?(d["policy.subscriber.person.hbx_id"])
      @data_hash[d["family.id"]] << d
    else
      @data_hash[d["family.id"]] = [d]
    end
  end
rescue Exception => e
  puts "Unable to open file #{e}" unless Rails.env.test?
end

field_names  = %w(
        family.id
        hbx_id
        full_name
      )
file_name = "#{Rails.root}/projected_eligibility_notice_1_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"

hbx = HbxProfile.current_hbx
bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if bcp.start_on.year.to_s == TimeKeeper.date_of_record.next_year.year.to_s }
CSV.open(file_name, "w", force_quotes: true) do |csv|
  csv << field_names

  event_kind = ApplicationEventKind.where(:event_name => 'projected_eligibility_notice_1').first
  notice_trigger = event_kind.notice_triggers.first
  @data_hash.each do |family_id , members|
    begin
      subscriber = members.detect{ |m| m["is_dependent"].upcase == "FALSE"}
      primary_person = HbxEnrollment.by_hbx_id(members.first["policy.id"]).first.family.primary_person rescue nil
      next if primary_person.nil?
      next if (subscriber.present? && subscriber["policy.subscriber.person.is_dc_resident?"] && subscriber["policy.subscriber.person.is_dc_resident?"].upcase == "FALSE")
      next if members.select{ |m| (m["policy.subscriber.person.is_incarcerated"] && m["policy.subscriber.person.is_incarcerated"].upcase == "TRUE")}.present?
      next if (members.any?{ |m| m["policy.subscriber.person.citizen_status"].blank? || (m["policy.subscriber.person.citizen_status"] == "non_native_not_lawfully_present_in_us") || (m["policy.subscriber.person.citizen_status"] == "not_lawfully_present_in_us")})
      consumer_role = primary_person.consumer_role
      if consumer_role.present?
        begin
          builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
              template: notice_trigger.notice_template,
              subject: event_kind.title,
              :event_name => event_kind.event_name,
              mpi_indicator: notice_trigger.mpi_indicator,
              person: primary_person,
              open_enrollment_start_on: bc_period.open_enrollment_start_on,
              open_enrollment_end_on: bc_period.open_enrollment_end_on,
              data: members
              }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)
              )
          builder.deliver
          csv << [
            family_id,
            primary_person.hbx_id,
            primary_person.full_name
          ]
          puts "***************** Notice delivered to #{primary_person.hbx_id} *****************" unless Rails.env.test?
        rescue Exception => e
          puts "Unable to deliver to #{primary_person.hbx_id} due to the following error #{e}" unless Rails.env.test?
        end
      else
        puts "No consumer role for #{primary_person.hbx_id} -- #{e}" unless Rails.env.test?
      end
    rescue => e
      puts "Unable to process family_id: #{family_id} due to the following error #{e}" unless Rails.env.test?
    end
  end
  puts "End of #{notice_trigger.mpi_indicator} notice generation" unless Rails.env.test?
end
puts "-------------------------------------- End of rake: #{TimeKeeper.datetime_of_record} --------------------------------------" unless Rails.env.test?
