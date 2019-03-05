puts "-------------------------------------- Start of rake: #{TimeKeeper.datetime_of_record} --------------------------------------" unless Rails.env.test?
begin
  @data_hash = {}
  CSV.foreach('proj_elig_report_aqhp_2018.csv',:headers =>true).each do |d|
    if @data_hash[d["ic_number"]].present?
      hbx_ids = @data_hash[d["ic_number"]].collect{|r| r['member_id']}
      next if hbx_ids.include?(d["member_id"])
      @data_hash[d["ic_number"]] << d
    else
      @data_hash[d["ic_number"]] = [d]
    end
  end
rescue Exception => e
  puts "Unable to open file #{e}" unless Rails.env.test?
end

field_names  = %w(
        ic_number
        hbx_id
        full_name
      )
file_name = "#{Rails.root}/projected_eligibility_notice_aqhp_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"

#open enrollment information
hbx = HbxProfile.current_hbx
bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if bcp.start_on.year.to_s == TimeKeeper.date_of_record.next_year.year.to_s }

CSV.open(file_name, "w", force_quotes: true) do |csv|
  csv << field_names
  event_kind = ApplicationEventKind.where(:event_name => 'projected_eligibility_notice_2').first
  notice_trigger = event_kind.notice_triggers.first
  @data_hash.each do |ic_number , members|
    begin
      primary_member = members.detect{ |m| m["dependent"].upcase == "NO"}
      dependents = members.select{|m| m["dependent"].upcase == "YES"}
      next if primary_member.nil?
      person = Person.where(:hbx_id => primary_member["subscriber_id"]).first
      primary_person = person.primary_family ? person : person.families.first.primary_applicant.person
      consumer_role = primary_person.consumer_role
      if primary_person.present? && consumer_role.present?
        if ARGV.include?("send_via_notice_eng")
          @notifier = Services::NoticeService.new
          @notifier.deliver(
            recipient: consumer_role,
            event_object: consumer_role,
            notice_event: 'projected_eligibility_notice_2',
            notice_params: {
              dependents: dependents.map{|mem| mem.to_hash},
              primary_member: primary_member.to_hash
            }
          )
        end
        puts "***************** Notice delivered to #{primary_person.hbx_id} *****************" unless Rails.env.test?
        csv << [
          ic_number,
          primary_person.hbx_id,
          primary_person.full_name
        ]
      else
        puts "No consumer role for #{primary_person.hbx_id} -- #{e}" unless Rails.env.test?
      end
    rescue Exception => e
      puts "Unable to deliver to projected_eligibility_notice_2 to #{ic_number} - ic number due to the following error #{e.backtrace}" unless Rails.env.test?
    end
  end
end
puts "-------------------------------------- End of rake: #{TimeKeeper.datetime_of_record} --------------------------------------" unless Rails.env.test?
