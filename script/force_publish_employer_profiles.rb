TERMED_EMPLOYERS = [ "454741440","464303739","521322260","521185005","521021282","510400233","521961415",
  "530196563","270360045","522094677","231520302","272141277","931169142","522062304","550864322","621469595",
  "521795954","522324745","273300538","264064164","000000028","363697513","200714211","200850720","451221231",
  "202853236","201743104","131954338","521996156","520746264","260839561","204098898","521818188","042751357",
  "521811081","521782065","237400898","830353971","742994661","522312249","521498887","261332221","521016137",
  "452400752","521103582","360753125","710863908","521309304","522022029","522197080","521826332"]


CSV.open("#{Rails.root}/public/force_published_employers.csv", "w", force_quotes: true) do |csv|
  csv << ['Legal Name', 'FEIN', 'Conversion Employer']
  EmployerProfile.organizations_for_force_publish(TimeKeeper.date_of_record).each do |organization|
    next if TERMED_EMPLOYERS.include?(organization.fein)
    puts 'Processing----' + organization.legal_name
    plan_year = organization.employer_profile.plan_years.where(:aasm_state => 'renewing_draft').first
    plan_year.force_publish!
    csv << [organization.legal_name, organization.fein, (organization.employer_profile.profile_source == 'conversion' ? 'TRUE' : 'FALSE')]
  end
end
