# This seed should be run after plans and admins are seeded
# admin seed generated Organization.where(dba:'DCHL') and we need Plans in db
puts "::: Creating Second Lowest Cost Silver Plan :::"
organization=Organization.where(dba:'DCHL').first
benifit_sponsorship=organization.hbx_profile.build_benefit_sponsorship
benifit_sponsorship.service_markets = %w(shop individual)
benifit_sponsorship.save!
benefit_coverage_period=benifit_sponsorship.benefit_coverage_periods.build()
benefit_coverage_period.start_on=Date.new(2015,1,1)
benefit_coverage_period.end_on=Date.new(2015,12,31)
benefit_coverage_period.open_enrollment_start_on=Date.new(2015,1,1)
benefit_coverage_period.open_enrollment_end_on=Date.new(2015,12,31)
benefit_coverage_period.service_market='shop'
benefit_coverage_period.slcsp=Plan.where(hios_id:/94506DC0390006-01/).and(name:'KP DC Silver 1750/25%/HSA/Dental/Ped Dental').first.id
benefit_coverage_period.save!
organization.save!
puts "::: Second Lowest Cost Silver Plan Complete :::"