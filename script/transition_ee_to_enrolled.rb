begin
  if ARGV[0].blank? || ARGV[1].blank?
    puts "please pass correct attributes"
    return
  end
  fein = ARGV[0]
  new_date = Date.new(ARGV[1].to_i, 1, 1)

  profile = BenefitSponsors::Organizations::Organization.where(fein: fein.to_s).first.employer_profile
  benefit_application = profile.benefit_applications.effective_date_begin_on(new_date).coverage_effective.first
  benefit_application.transition_benefit_package_members
  puts "Transition Completed"
rescue => e
  puts e
end