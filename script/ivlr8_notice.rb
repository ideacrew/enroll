
  begin
    csv = CSV.open('11455_export_glue_plan_family_no_dependents.csv',"r",:headers =>true,:encoding => 'ISO-8859-1')
    @data= csv.to_a
    @data_hash = {}
    @data.each do |d|
      if @data_hash[d["family.e_case_id"]].present?
        hbx_ids = @data_hash[d["family.e_case_id"]].collect{|r| r['person.authority_member_id']}
        @data_hash[d["family.e_case_id"]] << d
      else
        @data_hash[d["family.e_case_id"]] = [d]
      end
    end
  rescue Exception => e
    puts "Unable to open file #{e}"
  end
  
  field_names  = %w(
          family.e_case_id
          hbx_id
        )
  file_name = "#{Rails.root}/public/ivl_renewal_notice_2_report.csv"

  CSV.open(file_name, "w", force_quotes: true) do |csv|
    csv << field_names

    event_kind = ApplicationEventKind.where(:event_name => 'ivl_renewal_notice_8').first

    notice_trigger = event_kind.notice_triggers.first

    @data_hash.each do |e_case_id,members|
      begin
        primary_member = members[0]
        person = Person.where(:hbx_id => primary_member["person.authority_member_id"]).first
        address = {
          :address_1 => primary_member["glue_address_1"],
          :address_2 => primary_member["glue_address_2"],
          :city => primary_member["glue_city"],
          :state => primary_member["glue_state"],
          :zip => primary_member["glue_zip"]

        }
        consumer_role =person.consumer_role
        if consumer_role.present?
            builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
                  template: notice_trigger.notice_template,
                  subject: event_kind.title,
                  mpi_indicator: notice_trigger.mpi_indicator,
                  data: members,
                  person: person,
                  address: address,
                  primary_identifier: ic_ref
                  }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)
                  )
            builder.deliver
          csv << [
              ic_ref,
              person.hbx_id
            ]
        else
          puts "Unable to send notice to family_id : #{ic_ref}"
        end
      rescue Exception => e
        puts "Unable to deliver to #{ic_ref} for the following error #{e.backtrace}"
        next
      end
    end
  end