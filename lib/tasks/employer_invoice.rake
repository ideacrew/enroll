namespace :employer_invoice do
  desc "TODO"
  task generate: :environment do
    DO_NOT_INVOICE_LIST = [464303739, 521322260, 521185005, 521021282, 510400233,
      521961415, 530196563, 270360045, 522094677, 231520302, 272141277, 931169142,
      522062304, 550864322, 621469595, 521795954, 522324745, 273300538, 264064164,
      28, 363697513, 200714211, 200850720, 451221231, 202853236, 201743104, 131954338,
      521996156, 520746264, 260839561, 204098898, 521818188, 42751357, 521811081,
      521782065, 237400898, 830353971, 742994661, 522312249, 521498887, 261332221,
      521016137, 452400752, 521103582, 360753125, 710863908, 521309304, 522022029,
      522197080 ,521826332]
    @folder_name="DCEXCHANGE_#{TimeKeeper.date_of_record.strftime("%Y%m%d")}"
  	conversion_employers= Organization.where({
    :'employer_profile.profile_source' => 'conversion',
    :'employer_profile.plan_years' => { 
      :$elemMatch => {
          :"start_on" => { "$eq" => DateTime.parse("2016-07-01" ) } ,
          :"aasm_state".in =>  PlanYear::RENEWING_PUBLISHED_STATE 
        }
      }
    })

    # new_employers = Organization.where({
    #   :'employer_profile.plan_years' => { 
    #    :$elemMatch => {
    #      :start_on =>  { "$eq" => DateTime.parse("2016-07-01" ) },
    #      :"aasm_state".in => PlanYear::PUBLISHED
    #    }}
    # })

    generate_invoices(conversion_employers, false)
    # generate_invoices(new_employers, true)
   
    #Create a tar file 
    puts "creating a tar file now"
    	system("tar -zcvf #{@folder_name}.tar.gz #{@folder_name}")
    puts "Folder created!"

  end

  def generate_invoices(organizations, clean_up = nil )
     organizations.each do |org|
        unless DO_NOT_INVOICE_LIST.include?(org.fein) || !org.employer_profile.plan_years.renewing.first.try(:is_enrollment_valid?)
          if clean_up
            employer_invoice = EmployerInvoice.new(org,@folder_name)
            employer_invoice.save_and_notify_with_clean_up
          else
            employer_invoice = EmployerInvoice.new(org,@folder_name)
            employer_invoice.save_and_notify
          end
        end
      end
  end
end
