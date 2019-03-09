puts "-------------------------------------- Start of rake: #{TimeKeeper.datetime_of_record} --------------------------------------" unless Rails.env.test?
begin
  @data_hash = {}
  CSV.foreach('uqhp_projected_eligibility_notice_report.csv', :headers => true).each do |d|
    if @data_hash[d["family.id"]].present?
      hbx_ids = @data_hash[d["family.id"]].collect{|r| r['person_hbx_id']}
      next if hbx_ids.include?(d["person_hbx_id"])
      @data_hash[d["family.id"]] << d
    else
      @data_hash[d["family.id"]] = [d]
    end
  end
rescue StandardError => error
  puts "Unable to open file #{error}" unless Rails.env.test?
end

field_names = %w[family.id hbx_id full_name]
file_name = Rails.root.join(
  "projected_eligibility_notice_1_report_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv"
)

CSV.open(file_name, "w", force_quotes: true) do |csv|
  csv << field_names

  event_kind = ApplicationEventKind.where(:event_name => 'projected_eligibility_notice_1').first
  notice_trigger = event_kind.notice_triggers.first
  @data_hash.each do |family_id, members|
    #begin
      subscriber = members.detect{ |m| m["dependent"].casecmp('NO').zero? }
      dependents = members.select{|m| m["dependent"].casecmp('YES').zero? }
      primary_person = HbxEnrollment.by_hbx_id(members.first["applid"]).first.family.primary_person rescue nil
      next if primary_person.nil?
      next if subscriber.present? && subscriber["resident"] && subscriber["resident"].casecmp('NO').zero?
      next if members.select{ |m| m["incarcerated"] && m["incarcerated"].casecmp('YES').zero? }.present?
      next if members.any?{ |m| m["citizen_status"].blank? || (m["citizen_status"] == "non_native_not_lawfully_present_in_us") || (m["citizen_status"] == "not_lawfully_present_in_us")}
      consumer_role = primary_person.consumer_role
      if consumer_role.present?
        begin
          if ARGV.include?("send_via_notice_eng")
            binding.pry
            @notifier = Services::NoticeService.new
            @notifier.deliver(
              recipient: consumer_role,
              event_object: consumer_role,
              notice_event: 'projected_eligibility_notice_1',
              notice_params: {
                dependents: dependents.map(&:to_hash),
                primary_member: subscriber.to_hash
              }
            )
          end
          csv << [
            family_id,
            primary_person.hbx_id,
            primary_person.full_name
          ]
          puts "***************** Notice delivered to #{primary_person.hbx_id} *****************" unless Rails.env.test?
        rescue StandardError => e
          puts "Unable to deliver to #{primary_person.hbx_id} due to the following error #{e}" unless Rails.env.test?
        end
      else
        puts "No consumer role for #{primary_person.hbx_id} -- #{e}" unless Rails.env.test?
      end
    # rescue StandardError => e
    #   puts "Unable to process family_id: #{family_id} due to the following error #{e}" unless Rails.env.test?
    # end
  end
  puts "End of #{notice_trigger.mpi_indicator} notice generation" unless Rails.env.test?
end
puts "-------------------------------------- End of rake: #{TimeKeeper.datetime_of_record} --------------------------------------" unless Rails.env.test?
