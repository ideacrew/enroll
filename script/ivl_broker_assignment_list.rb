  require 'csv'
  
  batch_size = 500
  offset = 0

  ppl_count = Person.all_consumer_roles.count
  field_names  = %w(
             Full_Name
             Person_Hbxid
             Broker_Name
             Broker_NPN
             Broker_Assignment_Start
             Broker_Assignment_end
             )

  processed_count = 0
  file_name = "#{Rails.root}/ivl_broker_assignment_report_#{TimeKeeper.date_of_record.strftime("%m_%d_%Y")}.csv"
  date_range = Date.new(2016,1,1)..TimeKeeper.date_of_record
  CSV.open(file_name, "w", force_quotes: true) do |csv|
    csv << field_names
    while offset <= ppl_count
      Person.all_consumer_roles.offset(offset).limit(batch_size).each do |person|
        next if person.primary_family.nil? || person.primary_family.broker_agency_accounts.empty?
        person.primary_family.broker_agency_accounts.each do |ba_account|
          next if ba_account.nil? || ba_account.broker_agency_profile.nil? || ba_account.broker_agency_profile.primary_broker_role.nil?
          # csv << [
          #   person.full_name ,
          #   person.hbx_id,
          #   ba_account.broker_agency_profile.primary_broker_role.person.full_name,
          #   ba_account.broker_agency_profile.primary_broker_role.npn,
          #   ba_account.start_on,
          #   ba_account.end_on
          # ]
          puts person.full_name if !person.full_name.nil?
          puts person.id
        end
        processed_count += 1
      end
      offset = offset + batch_size
    end
    puts "For period #{date_range.first} - #{date_range.last}, #{processed_count} brokers to output file: #{file_name}" unless Rails.env.test?
  end
