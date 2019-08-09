  require 'csv'
  
  batch_size = 500
  offset = 0

  ppl_count = Family.exists("broker_agency_accounts" =>true).all.size
  field_names  = %w(
             First_Name
             Last_Name
             Person_Hbxid
             Broker_Name
             Broker_NPN
             Broker_Assignment_Start
             Broker_Assignment_end
             )

  @processed_count = 0
  file_name = "#{Rails.root}/ivl_broker_assignment_report_#{TimeKeeper.date_of_record.strftime("%m_%d_%Y")}.csv"
  date_range = Date.new(2016,1,1)..TimeKeeper.date_of_record
  CSV.open(file_name, "w", force_quotes: true) do |csv|
    csv << field_names
    while offset <= ppl_count
      Family.exists("broker_agency_accounts" =>true).all.offset(offset).limit(batch_size).each do |family|
        next if family.primary_person.nil? || family.broker_agency_accounts.empty?
        primary_person = family.primary_person

        family.broker_agency_accounts.each do |broker_agency_account|
          next if broker_agency_account.nil?
          next if broker_agency_account.broker_agency_profile.nil?
          next if broker_agency_account.broker_agency_profile.primary_broker_role.nil?
          broker_role = broker_agency_account.primary_broker_role
          csv << [
            primary_person.first_name,
            primary_person.last_name,
            primary_person.hbx_id,
            broker_role.person.full_name,
            broker_role.npn,
            broker_agency_account.start_on,
            broker_agency_account.end_on
          ]
        end
        puts @processed_count if @processed_count % 100 == 0
        @processed_count += 1
      end
      offset = offset + batch_size
    end
    puts "For period #{date_range.first} - #{date_range.last}, #{@processed_count} brokers to output file: #{file_name}" unless Rails.env.test?
  end
