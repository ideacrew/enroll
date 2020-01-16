# frozen_string_literal: true

# To run this script in PROD
# RAILS_ENV=production bundle exec rails runner script/generate_employer_renewals.rb "2019/10/1"

def benefit_renewal(date)
  months_prior_to_effective = Settings.aca.shop_market.renewal_application.earliest_start_prior_to_effective_on.months.abs
  renewal_offset_days = Settings.aca.shop_market.renewal_application.earliest_start_prior_to_effective_on.day_of_month.days
  renewal_application_begin = (date + months_prior_to_effective.months - renewal_offset_days)

  return unless renewal_application_begin.mday == 1
  benefit_sponsorships = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.may_renew_application?(renewal_application_begin.prev_day)
  puts "Total  Employers with 1/1/2019 PY: #{benefit_sponsorships.count}"
  BenefitSponsors::BenefitSponsorships::BenefitSponsorshipDirector.new(date).process(benefit_sponsorships, :renew_sponsor_benefit)
end

dates = ARGV

dates.each do |date|
  benefit_renewal(date.to_date)
end
