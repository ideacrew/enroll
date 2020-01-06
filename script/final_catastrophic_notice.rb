# rails runner script/final_catastrophic_notice.rb <file_name>, Example: rails runner script/final_catastrophic_notice.rb catastrophic_plans_report_for_2019.csv -e production
file_1 = ARGV[0]

if !file_1.present?
  puts "Please enter a valid file_name as an argument. Example: rails runner script/final_catastrophic_notice.rb catastrophic_plans_report_for_2019.csv"
  exit
end

begin
  csv_ea = CSV.open(file_1,"r",:headers =>true)
rescue Exception => e
  puts "Unable to open file #{e}"
end

@data_hash = {}
CSV.foreach(file_1,:headers =>true).each do |d|
  if @data_hash[d["Subscriber_HBX_ID"]].present?
    @data_hash[d["Subscriber_HBX_ID"]] << d
  else
    @data_hash[d["Subscriber_HBX_ID"]] = [d]
  end
end

@primary_people_hbx_ids = []

field_names = %w(
        primary_hbx_id
        primary_first_name
        primary_last_name
      )

file_2 = "#{Rails.root}/ivl_catastrophic_notice_report.csv"

event_kind = ApplicationEventKind.where(:event_name => 'final_catastrophic_plan').first
notice_trigger = event_kind.notice_triggers.first

CSV.open(file_2, "w", force_quotes: true) do |csv|
  csv << field_names
  @data_hash.each do |person_hbx_id , enrollments|
    begin
      grouped_families = enrollments.inject({}) do |fam_hash, enrollment|
                           ea_enrollment = HbxEnrollment.by_hbx_id(enrollment["Enrollment_Group_ID"]).first
                           family_id = ea_enrollment.family.id.to_s
                           if fam_hash[family_id].nil?
                             fam_hash[family_id] = [enrollment]
                           else
                             fam_hash[family_id] << enrollment
                           end
                           fam_hash
                         end

      grouped_families.each do |family_id, enrollments_by_family|
        #To verify the market kind
        enrollment_market_kinds = enrollments_by_family.inject([]) do |market_kinds, enrollment|
                                    ea_enrollment = HbxEnrollment.by_hbx_id(enrollment["Enrollment_Group_ID"]).first
                                    @family = ea_enrollment.family
                                    market_kinds << !ea_enrollment.is_shop? if ea_enrollment.present?
                                    market_kinds
                                  end

        #To verify the aasm state
        enrollment_aasm_states = enrollments_by_family.inject([]) do |states, enrollment|
                                   states << enrollment["State"]
                                 end.uniq

        #Reject if aasm_state is CANCELED and also reject if market kind is SHOP
        if (enrollment_aasm_states.count > 1 || ( enrollment_aasm_states.count == 1 && enrollment_aasm_states.first != "canceled")) && !(enrollment_market_kinds.include? false)
          person = @family.primary_person
          primary_hbx_id = person.hbx_id
          next if @primary_people_hbx_ids.include?(primary_hbx_id)
          consumer_role = person.consumer_role if person.present?
          if person.present? && consumer_role.present?
            begin
              builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
                          template: notice_trigger.notice_template,
                          subject: event_kind.title,
                          event_name: 'final_catastrophic_plan',
                          mpi_indicator: notice_trigger.mpi_indicator
                        }.merge(notice_trigger.notice_trigger_element_group.notice_peferences))
              builder.deliver

              csv << [
                primary_hbx_id,
                person.first_name,
                person.last_name
              ]
              @primary_people_hbx_ids << primary_hbx_id
              puts "CAT Notice is sent to primary person with hbx_id: #{primary_hbx_id}" unless Rails.env.test?
            rescue Exception => e
              puts "Unable to deliver to #{primary_hbx_id} for the following error #{e.backtrace}" unless Rails.env.test?
            end
          else
            puts "No Person or No consumer role exists for hbx_id: #{person_hbx_id}" unless Rails.env.test?
          end
        end
      end
    rescue => error
      puts "Message: #{error.message}, trace: #{error.backtrace}" unless Rails.env.test?
    end
  end
end
